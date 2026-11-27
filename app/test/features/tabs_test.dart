import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/features/shell/app_shell.dart';
import 'package:aurafit/models/options.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

final _answers = ProfileAnswers(
  goal: GoalType.loseFat,
  birthDate: DateTime(1998, 5, 10),
  sex: Sex.female,
  heightCm: 162,
  weightKg: 65,
  activity: ActivityLevel.lightlyActive,
  diet: DietType.veg,
);

NewMealEntry _poha(DateTime day) => NewMealEntry(
  name: 'Poha',
  meal: Meal.breakfast,
  day: day,
  portionUnit: 'plate',
  portionCount: 1,
  oilLevel: OilLevel.home,
  grams: 150,
  kcal: 270,
  proteinG: 6,
  carbsG: 42,
  fatG: 7,
  source: EntrySource.search,
);

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(AuraTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .last,
  );
  await tester.pumpAndSettle();
}

DateTime _daysAgo(int days) =>
    DateTime(testNow.year, testNow.month, testNow.day - days);

void main() {
  testWidgets('the four tabs open, and Yesterday carries from Today to Food', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      await pumpAura(
        tester,
        startAt: Routes.today,
        seed: (repo) => repo.saveProfile(_answers),
      );
      expect(find.text('TODAY'), findsOneWidget);
      expect(find.text('DAY 1'), findsOneWidget);
      expect(find.text('GOOD MORNING'), findsOneWidget);

      await _openTab(tester, 'Train');
      expect(find.text('TRAIN'), findsOneWidget);
      expect(find.textContaining('Josh is getting them ready'), findsOneWidget);
      await tester.tap(find.text('STEPS TODAY'));
      await tester.pumpAndSettle();
      expect(find.text('Steps walked'), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      await _openTab(tester, 'Progress');
      expect(find.text('PROGRESS'), findsOneWidget);

      await _openTab(tester, 'Today');
      await tester.tap(find.text('Yesterday'));
      await tester.pumpAndSettle();
      expect(find.text('YESTERDAY'), findsWidgets);

      await _openTab(tester, 'Food');
      expect(find.text('FOOD'), findsOneWidget);
      await _scrollTo(tester, find.text('EATEN YESTERDAY'));
      expect(find.text('EATEN YESTERDAY'), findsOneWidget);
    });
  });

  testWidgets('Progress shows the streak, the days logged and the weight '
      'trend', (tester) async {
    await withClock(Clock.fixed(testNow), () async {
      await pumpAura(
        tester,
        startAt: Routes.progress,
        seed: (repo) => repo.saveProfile(_answers),
        seedDb: (db) async {
          final log = LogRepository(db);
          for (final days in [4, 2, 0]) {
            await log.logEntry(_poha(_daysAgo(days)));
          }
          await log.saveWeightForDay(day: _daysAgo(14), weightKg: 66);
          await log.saveWeightForDay(day: _daysAgo(0), weightKg: 65.2);
        },
      );

      expect(find.text('3-DAY STREAK'), findsOneWidget);
      expect(
        find.text('Josh is a cub. 4 more days logged and he gets going.'),
        findsOneWidget,
      );

      // Logged days have Josh's fiery eyes; the days between are no guilt.
      expect(find.bySemanticsLabel('18 November: logged'), findsOneWidget);
      expect(find.bySemanticsLabel('19 November: no log'), findsOneWidget);
      expect(
        find.bySemanticsLabel('22 November, today: logged'),
        findsOneWidget,
      );
      // Before the first day logged, nothing reads as missed.
      expect(find.bySemanticsLabel('17 November'), findsOneWidget);
      expect(find.bySemanticsLabel('23 November'), findsOneWidget);

      // There's no month before the plan began, or after this one.
      for (final icon in [
        Icons.chevron_left_rounded,
        Icons.chevron_right_rounded,
      ]) {
        final button = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, icon),
        );
        expect(button.onPressed, isNull);
      }

      await _scrollTo(tester, find.text('0.8 kg down since 8 November'));
      expect(find.text('65.2 KG'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Weight trend: lowest 65.2 kg, highest 66 kg, latest 65.2 kg.',
        ),
        findsOneWidget,
      );
    });
  });
}
