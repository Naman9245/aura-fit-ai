import 'dart:async';

import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/food_repository.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/data/sync/sync_controller.dart';
import 'package:aurafit/data/sync/sync_engine.dart';
import 'package:aurafit/models/options.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_account_service.dart';
import '../helpers/fake_sync_remote.dart';

void main() {
  const me = Account(id: 'account-1', email: 'me@example.com');
  late AppDatabase db;
  late FakeSyncRemote remote;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    db = AppDatabase(NativeDatabase.memory());
    remote = FakeSyncRemote();
  });
  tearDown(() => db.close());

  Future<void> onboard() => ProfileRepository(db).saveProfile(
    ProfileAnswers(
      goal: GoalType.gainMuscle,
      birthDate: DateTime(2004, 8, 1),
      sex: Sex.male,
      heightCm: 175,
      weightKg: 64,
      activity: ActivityLevel.active,
    ),
  );

  /// Real timers, shortened: settle after 20 ms, retry after 100 ms, so a
  /// test second stands for the app's minutes.
  ProviderContainer start({Account? signedIn, FoodRepository? foods}) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (foods != null) foodRepositoryProvider.overrideWithValue(foods),
        accountServiceProvider.overrideWithValue(
          FakeAccountService(signedIn: signedIn),
        ),
        syncRemoteProvider.overrideWithValue(remote),
        syncSettleProvider.overrideWithValue(const Duration(milliseconds: 20)),
        syncRetryProvider.overrideWithValue(const Duration(milliseconds: 100)),
      ],
    );
    addTearDown(container.dispose);
    // The app listens for as long as it runs, as AuraApp does.
    container.listen(syncControllerProvider, (_, _) {});
    return container;
  }

  /// Waits until sync is [phase].
  Future<SyncStatus> until(ProviderContainer container, SyncPhase phase) {
    final reached = Completer<SyncStatus>();
    final listening = container.listen(syncControllerProvider, (_, status) {
      if (status.phase == phase && !reached.isCompleted) {
        reached.complete(status);
      }
    }, fireImmediately: true);
    return reached.future
        .timeout(const Duration(seconds: 5))
        .whenComplete(listening.close);
  }

  test('signed out: off, and nothing leaves the phone', () async {
    await onboard();
    final container = start();
    container.read(syncControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(container.read(syncControllerProvider).phase, SyncPhase.off);
    expect(remote.sent, isEmpty);
  });

  test('signed in, it syncs at once, then soon after each change', () async {
    await onboard();
    final container = start(signedIn: me);
    final synced = await until(container, SyncPhase.synced);
    expect(synced.lastSynced, isNotNull);
    expect(remote.rows('goals'), hasLength(1));

    await ProfileRepository(db).saveProfile(
      ProfileAnswers(
        goal: GoalType.maintain,
        birthDate: DateTime(2004, 8, 1),
        sex: Sex.male,
        heightCm: 175,
        weightKg: 64,
        activity: ActivityLevel.active,
      ),
    );
    await until(container, SyncPhase.syncing);
    await until(container, SyncPhase.synced);
    expect(remote.rows('goals'), hasLength(2));
  });

  // The app never seeds the catalogue into SQLite: search reads the bundled
  // file. So a phone has no 'foods' sync cursor, and a dish added or
  // corrected on the server must still reach it.
  test('a food added on the server reaches a phone with no catalogue '
      'cursor', () async {
    await onboard();
    // An empty bundle, so the server's first catalogue row is new to it.
    final foods = FoodRepository(db, loadSeedJson: () async => '[]');
    remote.put('foods', {
      'id': '019a9000-0000-7000-8000-000000009999',
      'name': 'Kathal Sabzi',
      'aliases': ['jackfruit curry'],
      'kcal_per_100g': 110,
      'protein_g_per_100g': 2.5,
      'carbs_g_per_100g': 14,
      'fat_g_per_100g': 5,
      'portions': [
        {'unit': 'katori', 'grams': 150},
      ],
      'assumption': 'Home style, 1 tsp oil a katori',
      'source': 'recipe',
      'updated_at': '2026-11-26T09:00:00Z',
      'deleted_at': null,
    });

    final container = start(signedIn: me, foods: foods);
    await until(container, SyncPhase.synced);

    final found = await foods.search('kathal');
    expect(found.map((f) => f.name), ['Kathal Sabzi']);
  });

  test('a log made offline goes up on the next retry once the network is '
      'back, with no change or reopening needed', () async {
    remote.offline = true;
    await onboard();
    final container = start(signedIn: me);
    await until(container, SyncPhase.offline);

    // The network comes back. Nothing else happens on the phone.
    final back = DateTime.now();
    remote.offline = false;
    await until(container, SyncPhase.synced);

    // Within one retry period (20 s in the app; 100 ms here), plus the time
    // the sync takes.
    expect(
      DateTime.now().difference(back),
      lessThan(const Duration(milliseconds: 600)),
    );
    expect(remote.rows('profiles'), hasLength(1));
    expect(remote.rows('goals'), hasLength(1));
    expect(remote.rows('weight_logs'), hasLength(1));
    expect(await SyncEngine.watchWaiting(db).first, 0);
  });

  test('nothing waiting, no retries while offline', () async {
    remote.offline = true;
    final container = start(signedIn: me);
    await until(container, SyncPhase.offline);
    final pushes = remote.pushes;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(remote.pushes, pushes);
    expect(container.read(syncControllerProvider).phase, SyncPhase.offline);
  });

  test('a sync asked for during one runs once more after it', () async {
    await onboard();
    final container = start(signedIn: me);
    final controller = container.read(syncControllerProvider.notifier);
    // Right after signing in, the new account is named.
    final first = controller.syncNow(as: me);
    final second = controller.syncNow(as: me);
    expect((await first).phase, SyncPhase.synced);
    expect((await second).phase, SyncPhase.synced);
  });

  test("another account's data: it stops, and says so", () async {
    await onboard();
    final first = start(signedIn: me);
    await until(first, SyncPhase.synced);
    first.dispose();

    final second = start(
      signedIn: const Account(id: 'account-2', email: 'other@example.com'),
    );
    await until(second, SyncPhase.otherAccount);
  });
}
