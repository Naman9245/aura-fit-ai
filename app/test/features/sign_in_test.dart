import 'package:aurafit/core/error_reporter.dart';
import 'package:aurafit/core/links.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/features/account/sign_in_screen.dart';
import 'package:aurafit/main.dart';
import 'package:aurafit/models/options.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_account_service.dart';
import '../helpers/fake_sync_remote.dart';

Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, String label, String text) async {
  final field = find.widgetWithText(TextField, label);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> _agree(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(Checkbox));
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
}

bool _enabled(WidgetTester tester, String label) {
  final button = find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
  );
  return tester.widget<ButtonStyleButton>(button).onPressed != null;
}

Future<void> _onboarded(ProfileRepository repo) => repo.saveProfile(
  ProfileAnswers(
    goal: GoalType.loseFat,
    birthDate: DateTime(1996, 5, 10),
    sex: Sex.female,
    heightCm: 155,
    weightKg: 50,
    activity: ActivityLevel.sedentary,
    diet: DietType.veg,
  ),
);

const _returning = SignInArgs(reason: SignInReason.returning);

/// A build that can send crash reports, starting with them on.
class _FakeCrashReports implements CrashReportSwitch {
  @override
  bool get available => true;

  @override
  bool on = true;

  @override
  Future<void> turn({required bool on}) async => this.on = on;
}

void main() {
  late FakeAccountService accounts;
  late FakeSyncRemote remote;

  setUp(() {
    accounts = FakeAccountService();
    remote = FakeSyncRemote();
  });

  testWidgets('a wrong password and an unknown email say the same thing', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      accounts.addAccount('priya@example.com', 'right-password');
      await pumpAura(
        tester,
        startAt: Routes.signIn,
        startExtra: _returning,
        accounts: accounts,
        remote: remote,
      );
      await _agree(tester);

      await _type(tester, 'Email', 'nobody@example.com');
      await _type(tester, 'Password', 'whatever-it-is');
      await _tap(tester, 'Sign in');
      expect(
        find.text('That email and password don\'t match.'),
        findsOneWidget,
      );

      await _type(tester, 'Email', 'priya@example.com');
      await _type(tester, 'Password', 'wrong-password');
      await _tap(tester, 'Sign in');
      expect(
        find.text('That email and password don\'t match.'),
        findsOneWidget,
      );
      expect(find.text('Welcome back', skipOffstage: false), findsOneWidget);
    });
  });

  testWidgets('every way of signing in waits for the consent box', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      await pumpAura(
        tester,
        startAt: Routes.signIn,
        accounts: accounts,
        remote: remote,
      );
      expect(find.text('Save your plan'), findsOneWidget);
      expect(find.text(consentText), findsOneWidget);
      expect(_enabled(tester, 'Continue with Google'), isFalse);
      expect(_enabled(tester, 'Create account'), isFalse);

      await _agree(tester);
      expect(_enabled(tester, 'Continue with Google'), isTrue);
      expect(_enabled(tester, 'Create account'), isTrue);
    });
  });

  testWidgets('a new account confirms its email with the code, then the '
      'plan made offline goes up to it', (tester) async {
    await withClock(Clock.fixed(testNow), () async {
      await pumpAura(
        tester,
        startAt: Routes.targets,
        seed: _onboarded,
        accounts: accounts,
        remote: remote,
      );
      await _tap(tester, 'Save my plan');
      await _agree(tester);
      await _type(tester, 'Email', '  Priya@Example.com ');
      await _type(tester, 'Password', 'short');
      await _tap(tester, 'Create account');
      expect(
        find.textContaining('at least 8 characters that\'s hard'),
        findsOneWidget,
      );
      await _type(tester, 'Password', 'long-enough-password');
      await _tap(tester, 'Create account');

      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('to priya@example.com.'), findsOneWidget);
      expect(accounts.codesSent, ['priya@example.com']);
      await _type(tester, 'Code', '654321');
      await _tap(tester, 'Confirm');
      expect(find.textContaining('That code is wrong'), findsOneWidget);
      await _type(tester, 'Code', FakeAccountService.code);
      await _tap(tester, 'Confirm');

      expect(find.text('Today'), findsWidgets);
      expect(find.byTooltip('Account'), findsOneWidget);
      expect(find.text('Save plan'), findsNothing);
      expect(remote.rows('profiles'), hasLength(1));
      expect(remote.rows('goals').values.single['calories_kcal'], 1200);
      expect(remote.rows('weight_logs'), hasLength(1));
    });
  });

  testWidgets('signing in before confirming goes to the code screen', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      accounts.addAccount(
        'arjun@example.com',
        'gym-every-day',
        confirmed: false,
      );
      await pumpAura(
        tester,
        startAt: Routes.signIn,
        startExtra: _returning,
        accounts: accounts,
        remote: remote,
      );
      await _agree(tester);
      await _type(tester, 'Email', 'arjun@example.com');
      await _type(tester, 'Password', 'gym-every-day');
      await _tap(tester, 'Sign in');

      expect(find.text('Check your email'), findsOneWidget);
      expect(accounts.codesSent, ['arjun@example.com']);
    });
  });

  testWidgets('"I already have an account" brings the plan down and skips '
      'onboarding', (tester) async {
    await withClock(Clock.fixed(testNow), () async {
      accounts.addAccount('arjun@example.com', 'gym-every-day');
      // The plan Arjun made on his other phone.
      final made = testNow.subtract(const Duration(days: 30)).toUtc();
      remote.put('profiles', {
        'birth_date': '2004-08-01',
        'sex': 'male',
        'height_cm': 175.0,
        'activity_level': 'active',
        'diet_type': null,
        'training_place': 'gym',
        'experience': 'beginner',
        'created_at': made.toIso8601String(),
        'updated_at': made.toIso8601String(),
        'deleted_at': null,
      });
      remote.put('goals', {
        'id': '019a8c3e-6a00-7000-8000-00000000a001',
        'goal_type': 'gain_muscle',
        'target_weight_kg': null,
        'basis_weight_kg': 64.0,
        'calories_kcal': 2950,
        'protein_g': 128,
        'carbs_g': 409,
        'fat_g': 82,
        'water_ml': 2240,
        'steps': 8000,
        'formula_version': 'v1',
        'started_at': made.toIso8601String(),
        'ended_at': null,
        'created_at': made.toIso8601String(),
        'updated_at': made.toIso8601String(),
        'deleted_at': null,
      });
      await pumpAura(
        tester,
        startAt: Routes.onboarding,
        accounts: accounts,
        remote: remote,
      );
      await _tap(tester, 'I already have an account');
      expect(find.text('Welcome back'), findsOneWidget);
      await _agree(tester);
      await _type(tester, 'Email', 'arjun@example.com');
      await _type(tester, 'Password', 'gym-every-day');
      await _tap(tester, 'Sign in');

      expect(find.text('Today'), findsWidgets);
      await _tap(tester, 'Targets');
      expect(find.text('Your daily targets'), findsOneWidget);
      expect(find.text('To gain muscle'), findsOneWidget);
      expect(find.text('2,950 kcal a day'), findsOneWidget);
    });
  });

  testWidgets('backing out of Google\'s picker leaves no error', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      accounts.google = null;
      await pumpAura(
        tester,
        startAt: Routes.signIn,
        accounts: accounts,
        remote: remote,
      );
      await _agree(tester);
      await _tap(tester, 'Continue with Google');

      expect(find.text('Save your plan', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('went wrong'), findsNothing);
    });
  });

  testWidgets('offline, signing in says so', (tester) async {
    await withClock(Clock.fixed(testNow), () async {
      accounts.offline = true;
      await pumpAura(
        tester,
        startAt: Routes.signIn,
        accounts: accounts,
        remote: remote,
      );
      await _agree(tester);
      await _tap(tester, 'Continue with Google');
      expect(find.textContaining('You\'re offline'), findsOneWidget);
    });
  });

  testWidgets('signing out names the changes still waiting, then takes the '
      'plan off the phone', (tester) async {
    await withClock(Clock.fixed(testNow), () async {
      remote.offline = true;
      final db = await pumpAura(
        tester,
        startAt: Routes.targets,
        seed: _onboarded,
        accounts: FakeAccountService(
          signedIn: const Account(id: 'email-1', email: 'priya@example.com'),
        ),
        remote: remote,
      );
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      expect(find.text('priya@example.com'), findsOneWidget);
      expect(find.textContaining('3 changes waiting'), findsOneWidget);

      await _tap(tester, 'Sign out');
      expect(
        find.textContaining('3 changes haven\'t reached your account yet'),
        findsOneWidget,
      );
      await _tap(tester, 'Sign out anyway');

      expect(find.text('What\'s your main goal?'), findsOneWidget);
      final left = await tester.runAsync(
        () async => [
          ...await db.select(db.profiles).get(),
          ...await db.select(db.goals).get(),
          ...await db.select(db.weightLogs).get(),
          ...await db.select(db.syncAccount).get(),
        ],
      );
      expect(left, isEmpty);
    });
  });

  testWidgets("another account's plan on the phone isn't mixed in", (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      accounts.addAccount(
        'other@example.com',
        'another-password',
        id: 'email-9',
      );
      await pumpAura(
        tester,
        startAt: Routes.signIn,
        startExtra: const SignInArgs(
          reason: SignInReason.expired,
          email: 'priya@example.com',
        ),
        seed: _onboarded,
        seedDb: (db) => db
            .into(db.syncAccount)
            .insert(
              SyncAccountCompanion.insert(
                accountId: 'email-1',
                email: const Value('priya@example.com'),
                boundAt: testNow,
              ),
            ),
        accounts: accounts,
        remote: remote,
      );
      expect(find.text('Sign in again'), findsOneWidget);
      await _agree(tester);
      await _type(tester, 'Email', 'other@example.com');
      await _type(tester, 'Password', 'another-password');
      await _tap(tester, 'Sign in');

      expect(
        find.text('This phone has another account\'s plan'),
        findsOneWidget,
      );
      expect(
        find.textContaining('belongs to priya@example.com'),
        findsOneWidget,
      );
      await _tap(tester, 'Cancel');

      expect(find.text('Sign in again', skipOffstage: false), findsOneWidget);
      expect(remote.sent, isEmpty);
    });
  });

  group('deleting the account', () {
    const priya = Account(id: 'email-1', email: 'priya@example.com');

    Future<AppDatabase> openSheet(WidgetTester tester) async {
      final db = await pumpAura(
        tester,
        startAt: Routes.targets,
        seed: _onboarded,
        accounts: accounts..signInAs(priya),
        remote: remote,
      );
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await _tap(tester, 'Delete account');
      expect(find.textContaining('It can\'t be undone'), findsOneWidget);
      return db;
    }

    testWidgets('removes it on the server and clears the phone', (
      tester,
    ) async {
      await withClock(Clock.fixed(testNow), () async {
        final db = await openSheet(tester);
        await _tap(tester, 'Delete everything');

        expect(accounts.deleted, ['email-1']);
        expect(find.text('What\'s your main goal?'), findsOneWidget);
        expect(
          find.text('Your account and everything in it are deleted.'),
          findsOneWidget,
        );
        final left = await tester.runAsync(
          () async => [
            ...await db.select(db.profiles).get(),
            ...await db.select(db.goals).get(),
            ...await db.select(db.weightLogs).get(),
            ...await db.select(db.syncAccount).get(),
          ],
        );
        expect(left, isEmpty);
      });
    });

    testWidgets('offline, deletes nothing anywhere and says so', (
      tester,
    ) async {
      await withClock(Clock.fixed(testNow), () async {
        final db = await openSheet(tester);
        accounts.offline = true;
        await _tap(tester, 'Delete everything');

        expect(accounts.deleted, isEmpty);
        expect(find.textContaining('nothing was deleted'), findsOneWidget);
        expect(find.text('priya@example.com'), findsOneWidget);
        final goals = await tester.runAsync(() => db.select(db.goals).get());
        expect(goals, hasLength(1));
      });
    });

    testWidgets('Cancel leaves everything as it was', (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        await openSheet(tester);
        await _tap(tester, 'Cancel');

        expect(accounts.deleted, isEmpty);
        expect(find.text('priya@example.com'), findsOneWidget);
      });
    });
  });

  group('the privacy policy and terms', () {
    final opened = <Uri>[];
    setUp(opened.clear);

    testWidgets('open from sign-in', (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        await pumpAura(
          tester,
          startAt: Routes.signIn,
          startExtra: _returning,
          accounts: accounts,
          remote: remote,
          openLink: (uri) async => opened.add(uri),
        );
        // At the foot of the screen, below the ways to sign in.
        await tester.scrollUntilVisible(
          find.text('Privacy policy'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await _tap(tester, 'Privacy policy');
        await _tap(tester, 'Terms');

        expect(opened, [AuraLinks.privacy, AuraLinks.terms]);
        expect(
          AuraLinks.privacy.toString(),
          'https://naman9245.github.io/aura-fit-ai/privacy/',
        );
      });
    });

    testWidgets('open from the account sheet', (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        await pumpAura(
          tester,
          startAt: Routes.targets,
          seed: _onboarded,
          accounts: accounts
            ..signInAs(const Account(id: 'email-1', email: 'p@example.com')),
          remote: remote,
          openLink: (uri) async => opened.add(uri),
        );
        await tester.tap(find.byTooltip('Account'));
        await tester.pumpAndSettle();
        await _tap(tester, 'Terms');

        expect(opened, [AuraLinks.terms]);
      });
    });
  });

  group('crash reports', () {
    const priya = Account(id: 'email-1', email: 'priya@example.com');

    Future<void> openSheet(
      WidgetTester tester,
      CrashReportSwitch crashReports,
    ) async {
      await pumpAura(
        tester,
        startAt: Routes.targets,
        seed: _onboarded,
        accounts: accounts..signInAs(priya),
        remote: remote,
        crashReports: crashReports,
      );
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
    }

    testWidgets('can be turned off from the account sheet', (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        final reports = _FakeCrashReports();
        await openSheet(tester, reports);

        final toggle = find.widgetWithText(
          SwitchListTile,
          'Send crash reports',
        );
        await tester.ensureVisible(toggle);
        expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
        await tester.tap(toggle);
        await tester.pumpAndSettle();

        expect(reports.on, isFalse);
        expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      });
    });

    testWidgets('show no switch in a build that can\'t send them', (
      tester,
    ) async {
      await withClock(Clock.fixed(testNow), () async {
        await openSheet(tester, crashReports);

        expect(find.text('Delete account'), findsOneWidget);
        expect(find.text('Send crash reports'), findsNothing);
      });
    });
  });

  group('the first screen', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<(String, Object?)> startFor({Account? signedIn}) {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          accountServiceProvider.overrideWithValue(
            FakeAccountService(signedIn: signedIn),
          ),
        ],
      );
      addTearDown(container.dispose);
      return startingPoint(container);
    }

    test('is onboarding with no plan yet', () async {
      expect((await startFor()).$1, Routes.onboarding);
    });

    test('is sign-in for a plan kept only on this phone', () async {
      await _onboarded(ProfileRepository(db));
      final (location, extra) = await startFor();
      expect(location, Routes.signIn);
      expect((extra! as SignInArgs).reason, SignInReason.savePlan);
    });

    test('is sign-in again when the session ended', () async {
      await _onboarded(ProfileRepository(db));
      await db
          .into(db.syncAccount)
          .insert(
            SyncAccountCompanion.insert(
              accountId: 'email-1',
              email: const Value('priya@example.com'),
              boundAt: testNow,
            ),
          );
      final (location, extra) = await startFor();
      expect(location, Routes.signIn);
      final args = extra! as SignInArgs;
      expect(args.reason, SignInReason.expired);
      expect(args.email, 'priya@example.com');
    });

    test('is Today when signed in', () async {
      await _onboarded(ProfileRepository(db));
      final (location, _) = await startFor(
        signedIn: const Account(id: 'email-1', email: 'priya@example.com'),
      );
      expect(location, Routes.today);
    });
  });
}
