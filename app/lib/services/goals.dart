import 'dart:math' as math;

import 'package:aurafit/core/format.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/targets.dart';
import 'package:aurafit/services/workouts.dart';
import 'package:flutter/foundation.dart';

/// The goals a day has.
enum GoalKind { calories, protein, water, steps, training }

/// One of the day's goals, how far along it is, and what's left.
@immutable
class DailyGoal {
  const DailyGoal({
    required this.kind,
    required this.title,
    required this.detail,
    required this.progress,
    required this.done,
    this.toGo,
  });

  final GoalKind kind;

  /// "Protein", "Water"...
  final String title;

  /// "72 of 120 g".
  final String detail;

  /// From 0 to 1.
  final double progress;
  final bool done;

  /// What's left, for Josh: "48 g of protein".
  final String? toGo;
}

/// A day's goals: calories on target, protein, water, steps, and the day's
/// training (a workout, or rest). Calories count as done close to the
/// target, never below the safe minimum: undereating is never a goal met.
List<DailyGoal> dailyGoals({
  required DaySummary summary,
  required GoalRow goal,
  required Sex? sex,
  required PlanDay? planDay,
  required bool trained,
}) {
  final eaten = summary.totalKcal.round();
  final target = goal.caloriesKcal;
  final low = math.max(calorieFloorKcal(sex), (target * 0.9).round());
  final high = (target * 1.05).round();
  final protein = summary.totalProteinG.round();

  DailyGoal measured(
    GoalKind kind,
    String title,
    int have,
    int want,
    String Function(int) amount,
    String what,
  ) => DailyGoal(
    kind: kind,
    title: title,
    detail: '${amount(have)} of ${amount(want)}',
    progress: want <= 0 ? 0 : (have / want).clamp(0.0, 1.0),
    done: want > 0 && have >= want,
    toGo: want > have ? '${amount(want - have)} of $what' : null,
  );

  return [
    DailyGoal(
      kind: GoalKind.calories,
      title: 'Calories on target',
      detail: '${formatWhole(eaten)} of ${formatWhole(target)} kcal',
      progress: target <= 0 ? 0 : (eaten / target).clamp(0.0, 1.0),
      done: eaten >= low && eaten <= high,
      toGo: eaten < low ? '${formatWhole(low - eaten)} kcal' : null,
    ),
    measured(
      GoalKind.protein,
      'Protein',
      protein,
      goal.proteinG,
      (g) => '$g g',
      'protein',
    ),
    measured(
      GoalKind.water,
      'Water',
      summary.waterMl,
      goal.waterMl,
      formatLitres,
      'water',
    ),
    measured(
      GoalKind.steps,
      'Steps',
      summary.steps,
      goal.steps,
      formatWhole,
      'steps',
    ),
    if (planDay != null)
      switch (planDay) {
        TrainingDay(:final workout) => DailyGoal(
          kind: GoalKind.training,
          title: 'Workout',
          detail: trained ? 'Done' : titleCase(workout.title),
          progress: trained ? 1 : 0,
          done: trained,
          toGo: trained ? null : 'your ${titleCase(workout.title)} workout',
        ),
        RestDay() || ActiveRestDay() => DailyGoal(
          kind: GoalKind.training,
          title: planDay is RestDay ? 'Rest day' : 'Active rest',
          detail: trained ? 'A bonus workout' : 'Recover well',
          progress: 1,
          done: true,
        ),
      },
  ];
}

/// "UPPER BODY A" as "Upper Body A".
String titleCase(String words) => words
    .toLowerCase()
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// What Josh says about the day's goals: never cross, always the next step.
String goalsLine(List<DailyGoal> goals, {required bool isToday}) {
  final done = goals.where((g) => g.done).length;
  final total = goals.length;
  if (done == total) {
    return isToday
        ? 'All $total goals done today! Josh is proud of you.'
        : 'All $total goals done. What a day.';
  }
  if (!isToday) {
    return '$done of $total goals done. Today\'s a new chance.';
  }
  // The open goal nearest to done is the next one to go for.
  final open = goals.where((g) => !g.done && g.toGo != null).toList()
    ..sort((a, b) => b.progress.compareTo(a.progress));
  if (open.isEmpty) return '$done of $total goals done. Keep going!';
  final next = open.first;
  if (done == 0) {
    return '$total goals today. Start with ${next.toGo}, you can do it!';
  }
  final cheer = next.progress >= 0.75 ? 'So close!' : 'You\'ve got this!';
  return '$done of $total done. ${next.toGo} to go. $cheer';
}
