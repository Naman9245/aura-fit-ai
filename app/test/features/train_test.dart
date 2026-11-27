import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

Future<void> _tap(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    // Further down a list, not built yet.
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .last,
    );
  }
  await tester.ensureVisible(target.first);
  await tester.pumpAndSettle();
  await tester.tap(target.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a gym plan: Sunday rest, Monday upper body, logged set by set', (
    tester,
  ) async {
    // testNow is a Sunday.
    await withClock(Clock.fixed(testNow), () async {
      final db = await pumpAura(
        tester,
        startAt: Routes.train,
        seed: (repo) => repo.saveProfile(
          ProfileAnswers(
            goal: GoalType.gainMuscle,
            birthDate: DateTime(1999, 1, 1),
            sex: Sex.male,
            heightCm: 175,
            weightKg: 70,
            activity: ActivityLevel.lightlyActive,
          ),
        ),
      );

      expect(find.text('WHERE DO YOU TRAIN?'), findsOneWidget);
      await _tap(tester, find.text('At a gym'));
      await _tap(tester, find.text('A year or more'));
      await _tap(tester, find.text('4 days'));
      await _tap(tester, find.text('Build my plan'));

      expect(find.text('Gym · 4 days'), findsOneWidget);
      expect(find.text('REST DAY'), findsOneWidget);

      await _tap(tester, find.bySemanticsLabel(RegExp('^monday')));
      expect(find.text('UPPER BODY A'), findsOneWidget);
      expect(find.text('Machine Chest Press'), findsNothing);
      expect(find.text('Barbell Bench Press'), findsOneWidget);

      await _tap(tester, find.text('Do it today'));
      expect(find.textContaining('0 / '), findsOneWidget);

      await tester.tap(find.byTooltip('More kilos, set 1').first);
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Mark set 1 done').first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Skip rest'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 / '), findsOneWidget);

      await _tap(tester, find.text('Finish early'));
      expect(find.text('WORKOUT DONE'), findsOneWidget);
      await _tap(tester, find.text('Done'));

      final sessions = await tester.runAsync(
        () => db.select(db.workoutSessions).get(),
      );
      expect(sessions, hasLength(1));
      expect(sessions!.single.workoutKey, 'upper_a');
      expect(sessions.single.setsDone, 1);
      expect(sessions.single.sets, contains('"kg":2.5'));

      // Today, Sunday, now shows as done in the week, at the top.
      await tester.scrollUntilVisible(
        find.bySemanticsLabel('sunday, done, today'),
        -300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      expect(find.bySemanticsLabel('sunday, done, today'), findsOneWidget);
    });
  });
}
