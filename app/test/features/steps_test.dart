import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/step_counter.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// A phone that has walked [today] steps today and [yesterday] yesterday.
class _FakeSteps implements StepCounter {
  _FakeSteps({this.today = 0, this.yesterday = 0});

  bool allowed = false;
  int today;
  int yesterday;
  bool started = false;

  @override
  Future<StepStatus> status() async =>
      StepStatus(available: true, allowed: allowed);

  @override
  Future<bool> requestPermission() async => allowed = true;

  @override
  Future<void> start() async => started = true;

  @override
  Future<int?> stepsBetween(DateTime from, DateTime to) async =>
      from.day == testNow.day ? today : yesterday;
}

void main() {
  test(
    'phone steps only ever raise the day, never lower a typed number',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final log = LogRepository(db);
      final day = DateTime(2026, 11, 22);

      expect(await log.savePhoneSteps(day: day, steps: 3000), isTrue);
      var steps = (await log.getDay(day)).stepsSamples;
      expect(steps.single.value, 3000);
      expect(steps.single.source, SampleSource.phone);

      expect(await log.savePhoneSteps(day: day, steps: 2500), isFalse);
      await log.setStepsForDay(day: day, steps: 9000);
      expect(await log.savePhoneSteps(day: day, steps: 8000), isFalse);
      expect((await log.getDay(day)).steps, 9000);
      expect(await log.savePhoneSteps(day: day, steps: 9500), isTrue);
      steps = (await log.getDay(day)).stepsSamples;
      expect(steps.single.value, 9500);
      expect(steps.single.source, SampleSource.phone);
    },
  );

  testWidgets('allowing the phone to count brings in today and yesterday', (
    tester,
  ) async {
    await withClock(Clock.fixed(testNow), () async {
      final phone = _FakeSteps(today: 4200, yesterday: 9100);
      final db = await pumpAura(
        tester,
        startAt: Routes.train,
        seed: (repo) => repo.saveProfile(
          ProfileAnswers(
            goal: GoalType.loseFat,
            birthDate: DateTime(1998, 5, 10),
            sex: Sex.female,
            heightCm: 162,
            weightKg: 65,
            activity: ActivityLevel.lightlyActive,
          ),
        ),
        overrides: [stepCounterProvider.overrideWithValue(phone)],
      );

      final button = find.text('Count my steps');
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(phone.started, isTrue);
      expect(find.text('Count my steps'), findsNothing);
      expect(find.textContaining('4,200 /'), findsOneWidget);
      expect(
        find.text('Counted by your phone. Tap to correct it.'),
        findsOneWidget,
      );
      final yesterday = await tester.runAsync(
        () => LogRepository(db).getDay(DateTime(2026, 11, 21)),
      );
      expect(yesterday!.steps, 9100);
    });
  });
}
