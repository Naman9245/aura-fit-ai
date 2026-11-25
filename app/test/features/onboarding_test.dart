import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Finder _field(String label) => find.widgetWithText(TextField, label);

Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _continue(WidgetTester tester) => _tap(tester, 'Continue');

bool _continueEnabled(WidgetTester tester) =>
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
        .onPressed !=
    null;

Future<void> _enterBirthDate(
  WidgetTester tester,
  String day,
  String month,
  String year,
) async {
  await tester.enterText(_field('Day'), day);
  await tester.enterText(_field('Month'), month);
  await tester.enterText(_field('Year'), year);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the 889 kcal case ends at 1,200 kcal, and says why', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      final db = await pumpAura(tester, startAt: Routes.onboarding);

      expect(find.text('What\'s your main goal?'), findsOneWidget);
      expect(_continueEnabled(tester), isFalse);
      await _tap(tester, 'Lose fat');
      await _continue(tester);

      await _enterBirthDate(tester, '10', '5', '1996');
      expect(find.text('10 May 1996: you\'re 30.'), findsOneWidget);
      await _continue(tester);

      await _tap(tester, 'Female');
      await _continue(tester);

      await _tap(tester, 'cm');
      await tester.enterText(_field('Height'), '155');
      await tester.enterText(_field('Weight'), '50');
      await tester.pumpAndSettle();
      await _continue(tester);

      await _tap(tester, 'Mostly sitting');
      await _continue(tester);

      // Diet is the last question until workouts ship (PRD A2, T1).
      expect(find.text('How do you train?'), findsNothing);
      await _tap(tester, 'Vegetarian');
      await _tap(tester, 'See my targets');

      expect(find.text('Your daily targets'), findsOneWidget);
      expect(find.text('1,200 kcal a day'), findsOneWidget);
      expect(find.textContaining('Raised to the safe minimum'), findsOneWidget);
      expect(
        find.textContaining('The formula gave 1,111 kcal'),
        findsOneWidget,
      );
      expect(find.text('90 g'), findsOneWidget, reason: '1.8 g × 50 kg');
      expect(find.text('1.75 L'), findsOneWidget, reason: '35 ml × 50 kg');
      expect(find.text('8,000'), findsOneWidget);

      await _tap(tester, 'How we calculated this');
      expect(find.text('4. The safe minimum'), findsOneWidget);
      expect(
        find.textContaining('1,111 kcal is below 1,200 kcal'),
        findsOneWidget,
      );
      expect(
        find.text('10 × 50 kg + 6.25 × 155 cm − 5 × 30 years − 161'),
        findsOneWidget,
      );
      expect(find.text('= 1,158 kcal'), findsOneWidget, reason: 'BMR 1,157.75');
      expect(find.text('= 1,389 kcal'), findsOneWidget, reason: '× 1.2');

      final goal = await tester.runAsync(ProfileRepository(db).activeGoal);
      expect(goal!.caloriesKcal, 1200);
      final profile = await tester.runAsync(ProfileRepository(db).profile);
      expect(profile!.dietType, DietType.veg);
      expect(profile.trainingPlace, isNull);
    });
  });

  group('birth date', () {
    Future<void> toBirthDate(WidgetTester tester) async {
      await _tap(tester, 'Lose fat');
      await _continue(tester);
    }

    testWidgets('refuses anyone under 18', (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        await pumpAura(tester, startAt: Routes.onboarding);
        await toBirthDate(tester);

        await _enterBirthDate(tester, '23', '11', '2008');

        expect(find.text('AURA is for adults, 18 and over'), findsOneWidget);
        expect(_continueEnabled(tester), isFalse);

        // Their 18th birthday was yesterday.
        await _enterBirthDate(tester, '21', '11', '2008');
        expect(_continueEnabled(tester), isTrue);
      });
    });

    testWidgets('refuses a date that doesn\'t exist', (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        await pumpAura(tester, startAt: Routes.onboarding);
        await toBirthDate(tester);

        await _enterBirthDate(tester, '31', '2', '1999');

        expect(find.text('That date doesn\'t exist'), findsOneWidget);
        expect(_continueEnabled(tester), isFalse);
      });
    });
  });

  testWidgets('height and weight must be in range', (tester) async {
    await withClock(Clock.fixed(testNow), () async {
      await pumpAura(tester, startAt: Routes.onboarding);
      await _tap(tester, 'Lose fat');
      await _continue(tester);
      await _enterBirthDate(tester, '1', '1', '1995');
      await _continue(tester);
      await _tap(tester, 'I\'d rather not say');
      await _continue(tester);

      await _tap(tester, 'cm');
      await tester.enterText(_field('Height'), '300');
      await tester.enterText(_field('Weight'), '70.5');
      await tester.pumpAndSettle();
      expect(find.text('Between 120 and 230 cm'), findsOneWidget);
      expect(_continueEnabled(tester), isFalse);

      await tester.enterText(_field('Height'), '172.5');
      await tester.pumpAndSettle();
      expect(find.text('Between 120 and 230 cm'), findsNothing);
      expect(_continueEnabled(tester), isTrue);

      // Only one decimal place goes in.
      await tester.enterText(_field('Weight'), '70.55');
      await tester.pumpAndSettle();
      expect(find.text('70.5'), findsOneWidget);

      // Switching to feet and inches carries the height across.
      await _tap(tester, 'ft + in');
      expect(find.text('= 172.5 cm'), findsOneWidget);
    });
  });

  testWidgets('height can be given in feet and inches', (tester) async {
    await withClock(Clock.fixed(testNow), () async {
      final db = await pumpAura(tester, startAt: Routes.onboarding);
      await _tap(tester, 'Lose fat');
      await _continue(tester);
      await _enterBirthDate(tester, '1', '1', '1995');
      await _continue(tester);
      await _tap(tester, 'Male');
      await _continue(tester);

      await tester.enterText(_field('Feet'), '5');
      await tester.enterText(_field('Inches'), '13');
      await tester.enterText(_field('Weight'), '70');
      await tester.pumpAndSettle();
      expect(find.text('Inches go up to 11'), findsOneWidget);
      expect(_continueEnabled(tester), isFalse);

      await tester.enterText(_field('Inches'), '7');
      await tester.pumpAndSettle();
      expect(find.text('= 170.2 cm'), findsOneWidget);
      await _continue(tester);
      await _tap(tester, 'Mostly sitting');
      await _continue(tester);
      await _tap(tester, 'See my targets');

      final profile = await tester.runAsync(
        () => db.select(db.profiles).getSingle(),
      );
      expect(profile!.heightCm, 170.2);
    });
  });

  testWidgets('going back keeps the answers', (tester) async {
    await withClock(Clock.fixed(testNow), () async {
      await pumpAura(tester, startAt: Routes.onboarding);
      await _tap(tester, 'Gain muscle');
      await _continue(tester);
      await _enterBirthDate(tester, '14', '3', '1998');
      await _continue(tester);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('14 March 1998: you\'re 28.'), findsOneWidget);

      // The phone's back button steps back too.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('What\'s your main goal?'), findsOneWidget);
      expect(_continueEnabled(tester), isTrue, reason: 'Gain muscle is kept');
    });
  });

  group('with targets saved', () {
    Future<void> seed(ProfileRepository repo) => repo.saveProfile(
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

    testWidgets('the app opens on them', (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        await pumpAura(tester, startAt: Routes.targets, seed: seed);

        expect(find.text('Your daily targets'), findsOneWidget);
        expect(find.text('To lose fat'), findsOneWidget);
        expect(find.text('1,200 kcal a day'), findsOneWidget);
      });
    });

    testWidgets(
      'changing a detail on one screen recalculates targets and keeps the old goal',
      (tester) async {
        await withClock(Clock.fixed(testNow), () async {
          final db = await pumpAura(
            tester,
            startAt: Routes.targets,
            seed: seed,
          );

          await _tap(tester, 'Change my details');
          expect(find.text('My details'), findsOneWidget);
          await _tap(tester, '50 kg');
          await tester.enterText(_field('Weight'), '60');
          await tester.pumpAndSettle();
          await _tap(tester, 'Save weight');

          await tester.pageBack();
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.text('Your daily targets', skipOffstage: false),
          );
          await tester.pumpAndSettle();
          expect(find.text('Your daily targets'), findsOneWidget);
          expect(find.text('108 g'), findsOneWidget, reason: '1.8 g × 60 kg');
          final goals = await tester.runAsync(() => db.select(db.goals).get());
          expect(goals, hasLength(2));
          expect(goals!.where((g) => g.endedAt == null), hasLength(1));
        });
      },
    );
  });
}
