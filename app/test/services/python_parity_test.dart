import 'dart:convert';
import 'dart:io';

import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/targets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the Dart maths against what the old Python maths returned for the
/// profiles in tool/export_python_targets.py.
///
/// Every number matches exactly, except where formula v1 deliberately
/// differs: a target below the calorie floor is raised to it, and negative
/// carbs are cut to zero. Those cases check the new rule instead.
void main() {
  final cases = (jsonDecode(
    File('test/fixtures/python_targets.json').readAsStringSync(),
  ) as List<Object?>).cast<Map<String, Object?>>();

  test('the fixture holds the 30 recorded profiles', () {
    expect(cases, hasLength(30));
  });

  for (final (index, c) in cases.indexed) {
    final input = c['input']! as Map<String, Object?>;
    final py = c['output']! as Map<String, Object?>;
    double num_(Map<String, Object?> map, String key) =>
        (map[key]! as num).toDouble();

    test('case $index (${c['why']}) gives the Python numbers', () {
      final t = calculateTargetsV1(
        TargetInputs(
          age: input['age']! as int,
          sex: _sex(input['gender']),
          heightCm: num_(input, 'height_cm'),
          weightKg: num_(input, 'weight_kg'),
          activity: _activity(input['activity_level']),
          goal: _goal(input['goal']),
        ),
      );

      // Everything before the floor is the same.
      expect(t.bmi, num_(py, 'bmi'), reason: 'bmi');
      expect(t.bmrKcal, num_(py, 'bmr'), reason: 'bmr');
      expect(
        t.maintenanceKcal,
        num_(py, 'maintenance_calories'),
        reason: 'maintenance',
      );
      expect(t.unflooredKcal, num_(py, 'calorie_goal'), reason: 'calories');
      expect(t.waterL, num_(py, 'water_liters'), reason: 'water');
      expect(t.steps, py['daily_step_target'], reason: 'steps');

      final pyCalories = num_(py, 'calorie_goal');
      final pyCarbs = num_(py, 'carbs_grams');
      if (pyCalories < t.floorKcal) {
        // Raised to the floor, with the macros worked out from it.
        expect(t.floorApplied, isTrue);
        expect(t.caloriesKcal, t.floorKcal);
        expect(
          t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9,
          closeTo(t.floorKcal, 2),
        );
      } else if (pyCarbs < 0) {
        // Carbs cut to zero, with fat taking what protein leaves.
        expect(t.carbRuleApplied, isTrue);
        expect(t.carbsG, 0);
        expect(t.proteinG, num_(py, 'protein_grams'));
        expect(t.fatG, lessThan(num_(py, 'fats_grams')));
      } else {
        expect(t.floorApplied, isFalse);
        expect(t.carbRuleApplied, isFalse);
        expect(t.caloriesKcal, pyCalories, reason: 'calories');
        expect(t.proteinG, num_(py, 'protein_grams'), reason: 'protein');
        expect(t.carbsG, pyCarbs, reason: 'carbs');
        expect(t.fatG, num_(py, 'fats_grams'), reason: 'fat');
      }
    });
  }

  test('the recorded profiles include floor, carb and rounding cases', () {
    final whys = cases.map((c) => c['why']! as String).toList();

    expect(whys, contains('floor, female'));
    expect(whys, contains('carbs below zero'));
    expect(whys, contains('rounding tie'));
  });
}

/// Python's gender strings. Its "other" is the same maths as no sex given.
Sex? _sex(Object? gender) => switch (gender) {
  'male' => Sex.male,
  'female' => Sex.female,
  'other' => null,
  _ => throw ArgumentError.value(gender, 'gender'),
};

ActivityLevel _activity(Object? level) => switch (level) {
  'sedentary' => ActivityLevel.sedentary,
  'lightly active' => ActivityLevel.lightlyActive,
  'active' => ActivityLevel.active,
  'athlete' => ActivityLevel.athlete,
  _ => throw ArgumentError.value(level, 'activity_level'),
};

GoalType _goal(Object? goal) => switch (goal) {
  'Gain Muscle' => GoalType.gainMuscle,
  'Lose Fat' => GoalType.loseFat,
  'Maintain Weight' => GoalType.maintain,
  'Body Recomposition' => GoalType.recomposition,
  'Athletic Performance' => GoalType.performance,
  _ => throw ArgumentError.value(goal, 'goal'),
};
