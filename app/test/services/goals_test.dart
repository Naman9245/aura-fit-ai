import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/goals.dart';
import 'package:aurafit/services/workouts.dart';
import 'package:flutter_test/flutter_test.dart';

final _day = DateTime(2026, 11, 23);

GoalRow _goal() => GoalRow(
  dirty: false,
  id: 'g',
  goalType: GoalType.loseFat,
  basisWeightKg: 65,
  caloriesKcal: 1800,
  proteinG: 100,
  carbsG: 200,
  fatG: 50,
  waterMl: 2500,
  steps: 8000,
  formulaVersion: 'v2',
  startedAt: _day,
  createdAt: _day,
  updatedAt: _day,
);

MealEntryRow _meal(double kcal, double protein) => MealEntryRow(
  dirty: false,
  id: '$kcal',
  name: 'Food',
  meal: Meal.lunch,
  day: _day,
  grams: 100,
  kcal: kcal,
  proteinG: protein,
  carbsG: 0,
  fatG: 0,
  eatenAt: _day,
  source: EntrySource.search,
  createdAt: _day,
  updatedAt: _day,
);

HealthSampleRow _sample(HealthMetric metric, double value) => HealthSampleRow(
  dirty: false,
  id: '$metric',
  metric: metric,
  day: _day,
  value: value,
  measuredAt: _day,
  source: SampleSource.manual,
  createdAt: _day,
  updatedAt: _day,
);

DaySummary _summary({
  double kcal = 0,
  double protein = 0,
  double water = 0,
  double steps = 0,
}) => DaySummary(
  day: _day,
  entries: [if (kcal > 0) _meal(kcal, protein)],
  waterSamples: [if (water > 0) _sample(HealthMetric.waterMl, water)],
  stepsSamples: [if (steps > 0) _sample(HealthMetric.steps, steps)],
  weightLog: null,
);

const _plan = TrainingPlan(
  place: TrainingPlace.home,
  days: 3,
  experience: Experience.beginner,
);

void main() {
  test('calories count only close to the target, never below safe', () {
    List<DailyGoal> goals(double kcal) => dailyGoals(
      summary: _summary(kcal: kcal),
      goal: _goal(),
      sex: Sex.female,
      planDay: null,
      trained: false,
    );
    expect(goals(1700).first.done, isTrue);
    expect(goals(1850).first.done, isTrue);
    expect(goals(1950).first.done, isFalse, reason: 'over by too much');
    expect(goals(1500).first.done, isFalse, reason: 'too far under');
    expect(goals(1500).first.toGo, '120 kcal');
    expect(goals(0), hasLength(4), reason: 'no workout goal without a plan');
  });

  test('protein, water, steps and the day\'s training', () {
    final monday = dailyGoals(
      summary: _summary(kcal: 1800, protein: 100, water: 2500, steps: 4000),
      goal: _goal(),
      sex: Sex.female,
      planDay: _plan.dayOf(DateTime.monday),
      trained: false,
    );
    expect([for (final g in monday) g.done], [true, true, true, false, false]);
    expect(monday[3].toGo, '4,000 of steps');
    expect(monday[4].toGo, 'your Full Body A workout');

    final sunday = dailyGoals(
      summary: _summary(),
      goal: _goal(),
      sex: Sex.female,
      planDay: _plan.dayOf(DateTime.sunday),
      trained: false,
    );
    expect(sunday.last.title, 'Rest day');
    expect(sunday.last.done, isTrue);
  });

  test('Josh names the next goal, and is never cross', () {
    final none = dailyGoals(
      summary: _summary(),
      goal: _goal(),
      sex: Sex.female,
      planDay: null,
      trained: false,
    );
    expect(goalsLine(none, isToday: true), startsWith('4 goals today. Start'));
    final most = dailyGoals(
      summary: _summary(kcal: 1800, protein: 90, water: 2500, steps: 8000),
      goal: _goal(),
      sex: Sex.female,
      planDay: null,
      trained: false,
    );
    expect(
      goalsLine(most, isToday: true),
      '3 of 4 done. 10 g of protein to go. So close!',
    );
    final all = dailyGoals(
      summary: _summary(kcal: 1800, protein: 100, water: 2500, steps: 8000),
      goal: _goal(),
      sex: Sex.female,
      planDay: null,
      trained: false,
    );
    expect(goalsLine(all, isToday: true), contains('proud'));
    expect(goalsLine(none, isToday: false), contains('new chance'));
  });
}
