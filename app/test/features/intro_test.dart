import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/fake_account_service.dart';
import '../helpers/fake_sync_remote.dart';

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// Josh moves for ever otherwise, and pumpAndSettle would never settle.
void _stillJosh(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _pumpIntro(WidgetTester tester) async {
  _stillJosh(tester);
  await pumpAura(tester, startAt: Routes.intro);
}

void main() {
  testWidgets('Josh walks a new person through to the first question', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      await _pumpIntro(tester);
      expect(find.text('NAMASTE!\nI\'M JOSH.'), findsOneWidget);
      expect(
        find.bySemanticsLabel(joshLabel(JoshMood.happy, JoshStage.cub)),
        findsOneWidget,
      );

      await _tap(tester, 'Hi Josh');
      expect(find.text('I BUILD\nYOUR PLAN'), findsOneWidget);
      await _tap(tester, 'Next');
      expect(find.text('I COACH\nEVERY SET'), findsOneWidget);
      await _tap(tester, 'Next');
      expect(find.text('EAT LIKE\nYOU TRAIN'), findsOneWidget);
      await _tap(tester, 'Next');
      expect(find.text('WE\'LL DO THIS\nTOGETHER.'), findsOneWidget);
      expect(
        find.bySemanticsLabel(joshLabel(JoshMood.fired, JoshStage.beastMode)),
        findsOneWidget,
      );
      expect(find.text('Skip'), findsNothing);

      await _tap(tester, 'Let\'s go');
      expect(find.text('What\'s your main goal?'), findsOneWidget);
    });
  });

  testWidgets('Skip goes to the last screen, and Back steps back', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      await _pumpIntro(tester);
      await _tap(tester, 'Skip');
      expect(find.text('WE\'LL DO THIS\nTOGETHER.'), findsOneWidget);

      await _tap(tester, 'Back');
      expect(find.text('EAT LIKE\nYOU TRAIN'), findsOneWidget);
    });
  });

  testWidgets('Meet Josh again replays the intro and comes back', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      _stillJosh(tester);
      await pumpAura(
        tester,
        startAt: Routes.targets,
        seed: (repo) => repo.saveProfile(
          ProfileAnswers(
            goal: GoalType.loseFat,
            birthDate: DateTime(1996, 5, 10),
            sex: Sex.female,
            heightCm: 155,
            weightKg: 50,
            activity: ActivityLevel.sedentary,
            diet: DietType.veg,
          ),
        ),
        accounts: FakeAccountService()
          ..signInAs(const Account(id: 'email-1', email: 'p@example.com')),
        remote: FakeSyncRemote(),
      );
      await tester.tap(find.byTooltip('Account'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Meet Josh again'));
      await _tap(tester, 'Meet Josh again');
      expect(find.text('NAMASTE!\nI\'M JOSH.'), findsOneWidget);

      await _tap(tester, 'Skip');
      await _tap(tester, 'Let\'s go');
      expect(find.text('What\'s your main goal?'), findsNothing);
      expect(find.byTooltip('Account'), findsOneWidget);
    });
  });
}
