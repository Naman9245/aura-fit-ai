import 'package:aurafit/data/account_data.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/data/sync/sync_engine.dart';
import 'package:aurafit/data/sync/sync_remote.dart';
import 'package:aurafit/models/options.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value, Variable, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import '../helpers/fake_sync_remote.dart';

/// Onboarding's answers: the 889 kcal case, which ends at 1,200 kcal.
ProfileAnswers _answers({double weightKg = 50, double heightCm = 155}) =>
    ProfileAnswers(
      goal: GoalType.loseFat,
      birthDate: DateTime(1996, 5, 10),
      sex: Sex.female,
      heightCm: heightCm,
      weightKg: weightKg,
      activity: ActivityLevel.sedentary,
      diet: DietType.veg,
    );

String _iso(DateTime at) => at.toUtc().toIso8601String();

/// One phone: its own database, syncing with [remote].
class _Phone {
  _Phone(this.remote, this.now);

  final FakeSyncRemote remote;
  DateTime now;
  final db = AppDatabase(NativeDatabase.memory());
  final refused = <RefusedRow>{};
  final logs = <String>[];

  /// Runs [action] with the phone's clock at [now].
  Future<T> at<T>(Future<T> Function() action) =>
      withClock(Clock.fixed(now), action);

  ProfileRepository get repo => ProfileRepository(db);

  Future<void> onboard({double weightKg = 50}) =>
      at(() => repo.saveProfile(_answers(weightKg: weightKg)));

  Future<void> sync({String account = 'account-1'}) => at(
    () => SyncEngine(
      db,
      remote,
      clock: () => now,
      refused: refused,
      log: logs.add,
    ).sync(account, email: 'me@example.com'),
  );

  Future<int> waiting() => SyncEngine.watchWaiting(db).first;

  Future<String> addMeal(String name) async {
    final id = const Uuid().v7();
    await db
        .into(db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            id: id,
            name: name,
            meal: Meal.lunch,
            day: DateTime(now.year, now.month, now.day),
            grams: 150,
            kcal: 180,
            proteinG: 9,
            carbsG: 25,
            fatG: 4,
            eatenAt: now,
            source: EntrySource.search,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Every row of [table] here, as plain values, by id.
  Future<Map<Object?, Map<String, Object?>>> table(String table) async {
    final rows = await db.customSelect('SELECT * FROM $table').get();
    return {
      for (final row in rows) row.data['id']: {...row.data}..remove('dirty'),
    };
  }
}

void main() {
  final start = DateTime(2026, 11, 22, 9);
  late FakeSyncRemote remote;
  late _Phone phone;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    remote = FakeSyncRemote();
    phone = _Phone(remote, start);
  });
  tearDown(() => phone.db.close());

  test('a first sync sends what onboarding saved, as it is', () async {
    await phone.onboard();
    expect(await phone.waiting(), 3);

    await phone.sync();

    final profile = remote.rows('profiles')['me']!;
    expect(profile.containsKey('id'), isFalse, reason: 'keyed by the account');
    expect(profile['birth_date'], '1996-05-10');
    expect(profile['sex'], 'female');
    expect(profile['height_cm'], 155.0);
    expect(profile['activity_level'], 'sedentary');
    expect(profile['diet_type'], 'veg');
    expect(profile['created_at'], _iso(start));
    final goal = remote.rows('goals').values.single;
    expect(goal['calories_kcal'], 1200);
    expect(goal['basis_weight_kg'], 50.0);
    expect(goal['started_at'], _iso(start));
    expect(goal['ended_at'], isNull);
    expect(goal.containsKey('dirty'), isFalse);
    expect(remote.rows('weight_logs').values.single['day'], '2026-11-22');
    expect(await phone.waiting(), 0);
    expect(
      (await AccountData(phone.db).owner())?.accountId,
      'account-1',
      reason: 'the data now belongs to that account',
    );
  });

  test('changing my details sends the ended goal before the new one', () async {
    await phone.onboard();
    await phone.sync();

    phone.now = start.add(const Duration(hours: 1));
    await phone.onboard(weightKg: 56);
    await phone.sync();

    final goals = remote.rows('goals').values.toList();
    expect(goals, hasLength(2));
    final live = goals.where((g) => g['ended_at'] == null).toList();
    expect(live.single['basis_weight_kg'], 56.0);
    // The server takes one active goal at a time, so order matters.
    final lastSent = remote.sent['goals']!.sublist(1);
    expect(lastSent.first['ended_at'], isNotNull);
    expect(lastSent.last['ended_at'], isNull);
    expect(await phone.waiting(), 0);
  });

  test('the newer edit wins, here and in the copy', () async {
    await phone.onboard();
    await phone.sync();
    final goalId = remote.rows('goals').keys.single;

    // Another phone changes the steps later: it comes down, and isn't sent
    // back.
    phone.now = start.add(const Duration(hours: 1));
    remote.put('goals', {
      ...remote.rows('goals')[goalId]!,
      'steps': 9000,
      'updated_at': _iso(phone.now),
    });
    await phone.sync();
    expect((await phone.repo.activeGoal())!.steps, 9000);
    expect(await phone.waiting(), 0);

    // An older copy arriving later doesn't undo it.
    remote.put('goals', {
      ...remote.rows('goals')[goalId]!,
      'steps': 1,
      'updated_at': _iso(start),
    });
    await phone.sync();
    expect((await phone.repo.activeGoal())!.steps, 9000);
  });

  test('an edit the copy has a newer one of gives way to it', () async {
    await phone.onboard();
    await phone.sync();

    // Another phone edits the profile at 11:00; this one at 10:00, before
    // hearing of it.
    remote.put(
      'profiles',
      {
        ...remote.rows('profiles')['me']!,
        'height_cm': 160.0,
        'updated_at': _iso(start.add(const Duration(hours: 2))),
      }..remove('seq'),
    );
    phone.now = start.add(const Duration(hours: 1));
    await phone.at(
      () => phone.db
          .update(phone.db.profiles)
          .write(
            ProfilesCompanion(
              heightCm: const Value(158),
              updatedAt: Value(phone.now),
              dirty: const Value(true),
            ),
          ),
    );
    await phone.sync();

    expect((await phone.repo.profile())!.heightCm, 160);
    expect(await phone.waiting(), 0);
  });

  test('a reply lost on the way leaves one row on the server', () async {
    await phone.onboard();
    remote.loseNextReply = true;
    await expectLater(
      phone.sync(),
      throwsA(
        isA<SyncException>().having(
          (e) => e.failure,
          'failure',
          SyncFailure.offline,
        ),
      ),
    );
    expect(await phone.waiting(), greaterThan(0));

    await phone.sync();

    expect(remote.rows('profiles'), hasLength(1));
    expect(remote.rows('goals'), hasLength(1));
    expect(remote.rows('weight_logs'), hasLength(1));
    expect(await phone.waiting(), 0);
  });

  test('offline, nothing is lost: the next sync sends it', () async {
    await phone.onboard();
    final id = await phone.addMeal('Dal');
    remote.offline = true;
    await expectLater(phone.sync(), throwsA(isA<SyncException>()));
    expect(await phone.waiting(), 4);

    remote.offline = false;
    await phone.sync();
    expect(remote.rows('meal_entries'), contains(id));
    expect(await phone.waiting(), 0);
  });

  test("this phone's data never goes to another account", () async {
    await phone.onboard();
    await phone.sync();

    final other = FakeSyncRemote();
    await expectLater(
      SyncEngine(phone.db, other).sync('account-2'),
      throwsA(
        isA<SyncException>().having(
          (e) => e.failure,
          'failure',
          SyncFailure.otherAccount,
        ),
      ),
    );
    expect(other.sent, isEmpty);
  });

  group('two phones that both onboarded offline', () {
    late _Phone older;
    late _Phone newer;

    setUp(() async {
      older = phone;
      newer = _Phone(remote, start.add(const Duration(hours: 1)));
      await older.onboard(weightKg: 50);
      await newer.onboard(weightKg: 52);
    });
    tearDown(() => newer.db.close());

    for (final olderFirst in [true, false]) {
      test('end the same, with the newer goal active '
          '(${olderFirst ? 'older' : 'newer'} phone syncs first)', () async {
        final first = olderFirst ? older : newer;
        final second = olderFirst ? newer : older;
        older.now = newer.now = start.add(const Duration(hours: 2));
        await first.sync();
        await second.sync();
        await first.sync();

        for (final table in ['profiles', 'goals', 'weight_logs']) {
          expect(
            await older.table(table),
            await newer.table(table),
            reason: table,
          );
        }
        final goals = remote.rows('goals').values.toList();
        expect(goals, hasLength(2), reason: 'the older one kept as history');
        final active = goals.where((g) => g['ended_at'] == null).toList();
        expect(active.single['basis_weight_kg'], 52.0);
        final weighIns = remote.rows('weight_logs').values;
        expect(
          weighIns.where((w) => w['deleted_at'] == null).single['weight_kg'],
          52.0,
        );
        expect((await older.repo.activeGoal())!.basisWeightKg, 52);
        expect(await older.waiting(), 0);
        expect(await newer.waiting(), 0);
      });
    }
  });

  test(
    'a goal set on another phone mid-sync is settled, not refused',
    () async {
      await phone.onboard();
      // The other phone's goal lands between this phone's fetch and send.
      remote.beforePush = (table) {
        if (table != 'goals') return;
        remote.beforePush = null;
        final later = start.add(const Duration(minutes: 30));
        remote.put('goals', {
          'id': const Uuid().v7(),
          'goal_type': 'maintain',
          'target_weight_kg': null,
          'basis_weight_kg': 50.0,
          'calories_kcal': 1500,
          'protein_g': 80,
          'carbs_g': 180,
          'fat_g': 50,
          'water_ml': 1750,
          'steps': 8000,
          'formula_version': 'v1',
          'started_at': _iso(later),
          'ended_at': null,
          'created_at': _iso(later),
          'updated_at': _iso(later),
          'deleted_at': null,
        });
      };
      phone.now = start.add(const Duration(hours: 1));

      await phone.sync();

      final active = remote
          .rows('goals')
          .values
          .where((g) => g['ended_at'] == null);
      expect(active.single['goal_type'], 'maintain');
      expect((await phone.repo.activeGoal())!.goalType, GoalType.maintain);
      expect(await phone.waiting(), 0);
    },
  );

  test('a row the server refuses stays here, and the rest go up', () async {
    final good = await phone.addMeal('Dal');
    final bad = await phone.addMeal('Broken');
    final alsoGood = await phone.addMeal('Roti');
    remote.refuse = (table, row) => row['name'] == 'Broken';

    await phone.sync();

    expect(remote.rows('meal_entries').keys, unorderedEquals([good, alsoGood]));
    expect(await phone.waiting(), 1);
    expect(phone.logs.single, contains('meal_entries row (23514)'));
    expect(phone.logs.single, isNot(contains('Broken')));

    // It isn't sent again while it stays as it was.
    final pushes = remote.pushes;
    await phone.sync();
    expect(remote.pushes, pushes);

    // Once it changes here, it gets another try.
    remote.refuse = null;
    phone.now = start.add(const Duration(minutes: 5));
    await phone.db.customUpdate(
      "UPDATE meal_entries SET name = 'Rajma', dirty = 1, "
      'updated_at = updated_at + 300 WHERE id = ?',
      variables: [Variable(bad)],
    );
    await phone.sync();
    expect(remote.rows('meal_entries')[bad]!['name'], 'Rajma');
    expect(await phone.waiting(), 0);
  });

  test("another phone's profile becomes this phone's one profile", () async {
    await phone.onboard();
    await phone.sync();
    remote.put(
      'profiles',
      {
        ...remote.rows('profiles')['me']!,
        'training_place': 'gym',
        'updated_at': _iso(start.add(const Duration(hours: 1))),
      }..remove('seq'),
    );

    await phone.sync();

    final profiles = await phone.db.select(phone.db.profiles).get();
    expect(profiles.single.id, 1);
    expect(profiles.single.trainingPlace, TrainingPlace.gym);
  });

  test('a big copy comes down in pages', () async {
    for (var i = 0; i < SyncEngine.batch * 2 + 1; i++) {
      remote.put('health_samples', {
        'id': '019a8c3e-6a00-7000-8000-${i.toString().padLeft(12, '0')}',
        'metric': 'water_ml',
        'day': '2026-11-22',
        'value': 250,
        'measured_at': _iso(start),
        'source': 'manual',
        'created_at': _iso(start),
        'updated_at': _iso(start),
        'deleted_at': null,
      });
    }
    await phone.sync();
    expect(
      await phone.db.select(phone.db.healthSamples).get(),
      hasLength(SyncEngine.batch * 2 + 1),
    );
    expect(await phone.waiting(), 0);
  });
}
