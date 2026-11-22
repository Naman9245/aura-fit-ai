import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/targets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The profile the Python tests used: 70 kg, 175 cm, 25 years.
Targets _python(GoalType goal, ActivityLevel activity, {Sex? sex = Sex.male}) =>
    calculateTargets(
      TargetInputs(
        age: 25,
        sex: sex,
        heightCm: 175,
        weightKg: 70,
        activity: activity,
        goal: goal,
      ),
    );

double _macroKcal(Targets t) => t.proteinG * 4 + t.carbsG * 4 + t.fatG * 9;

void main() {
  group('ported from test_calculations.py', () {
    test('BMI is weight over height squared', () {
      expect(bmi(70, 175), 22.86);
    });

    for (final (sex, expected) in [
      (Sex.male, 1673.75),
      (Sex.female, 1507.75),
      (null, 1590.75),
    ]) {
      test(
        'BMR uses the Mifflin-St Jeor equation (${sex?.name ?? 'no sex given'})',
        () {
          expect(
            bmrKcal(weightKg: 70, heightCm: 175, age: 25, sex: sex),
            expected,
          );
        },
      );
    }

    for (final goal in GoalType.values) {
      test('macros add up to the calorie goal (${goal.name})', () {
        final t = _python(goal, ActivityLevel.active);

        expect(_macroKcal(t), closeTo(t.caloriesKcal, 2));
      });
    }

    test('a fat loss goal is a 500 calorie deficit', () {
      final t = _python(GoalType.loseFat, ActivityLevel.sedentary);

      expect(t.maintenanceKcal, closeTo(1673.75 * 1.2, 0.01));
      expect(t.caloriesKcal, closeTo(t.maintenanceKcal - 500, 0.01));
    });

    test('active people get more water and a higher step target', () {
      final sedentary = _python(GoalType.maintain, ActivityLevel.sedentary);
      final athlete = _python(GoalType.maintain, ActivityLevel.athlete);

      expect(athlete.waterL, closeTo(sedentary.waterL + 0.5, 1e-9));
      expect((sedentary.steps, athlete.steps), (8000, 13000));
    });

    // In Python these were strings checked at run time. Here the maths takes
    // enums, so the check moves to reading a stored option.
    test('unknown options raise instead of guessing (activity)', () {
      expect(
        () => parseOption(ActivityLevel.values, 'couch'),
        throwsArgumentError,
      );
    });

    test('unknown options raise instead of guessing (goal)', () {
      expect(
        () => parseOption(GoalType.values, 'get_rich'),
        throwsArgumentError,
      );
    });
  });

  group('calorie floor', () {
    TargetInputs small(Sex? sex) => TargetInputs(
      age: 30,
      sex: sex,
      heightCm: 155,
      weightKg: 50,
      activity: ActivityLevel.sedentary,
      goal: GoalType.loseFat,
    );

    test('the 889 kcal case is raised to 1,200 kcal for a woman', () {
      final t = calculateTargets(small(Sex.female));

      expect(t.unflooredKcal, 889.3);
      expect(t.caloriesKcal, 1200);
      expect(t.floorApplied, isTrue);
    });

    test('a man is never below 1,500 kcal', () {
      final t = calculateTargets(small(Sex.male));

      expect(t.unflooredKcal, lessThan(1500));
      expect(t.caloriesKcal, 1500);
      expect(t.floorApplied, isTrue);
    });

    test('with no sex given, the higher floor of 1,500 kcal applies', () {
      final t = calculateTargets(small(null));

      expect(t.caloriesKcal, 1500);
      expect(t.floorKcal, 1500);
    });

    test('a target above the floor is left alone', () {
      final t = _python(GoalType.loseFat, ActivityLevel.active);

      expect(t.floorApplied, isFalse);
      expect(t.caloriesKcal, t.unflooredKcal);
    });

    test('macros are worked out from the raised target', () {
      final t = calculateTargets(small(Sex.female));

      expect(_macroKcal(t), closeTo(1200, 2));
    });
  });

  group('carbs never go negative', () {
    test('fat gives way first', () {
      // Python gave -6.2 g of carbs for this profile.
      final t = calculateTargets(
        const TargetInputs(
          age: 100,
          sex: Sex.female,
          heightCm: 120,
          weightKg: 150,
          activity: ActivityLevel.sedentary,
          goal: GoalType.loseFat,
        ),
      );

      expect(t.carbRuleApplied, isTrue);
      expect(t.carbsG, 0);
      expect(t.proteinG, 270);
      expect(t.fatG, closeTo((1406.8 - 270 * 4) / 9, 0.05));
      expect(_macroKcal(t), closeTo(t.caloriesKcal, 1));
    });

    test('then protein, when protein alone is more than the calories', () {
      // Far outside what onboarding accepts, but the maths stays safe: 360 g
      // of protein would be 1,440 kcal, over the 1,200 kcal target.
      final t = calculateTargets(
        const TargetInputs(
          age: 150,
          sex: Sex.female,
          heightCm: 50,
          weightKg: 200,
          activity: ActivityLevel.sedentary,
          goal: GoalType.loseFat,
        ),
      );

      expect(t.carbRuleApplied, isTrue);
      expect(t.caloriesKcal, 1200);
      expect((t.carbsG, t.fatG), (0, 0));
      expect(t.proteinG, 300);
    });

    test('no target is negative or below the floor, anywhere in range', () {
      var checked = 0;
      for (final age in [18, 30, 50, 75, 100]) {
        for (final weight in [30.0, 50.0, 80.0, 120.0, 180.0, 250.0]) {
          for (final height in [120.0, 150.0, 175.0, 200.0, 230.0]) {
            for (final sex in [...Sex.values, null]) {
              for (final activity in ActivityLevel.values) {
                for (final goal in GoalType.values) {
                  final t = calculateTargets(
                    TargetInputs(
                      age: age,
                      sex: sex,
                      heightCm: height,
                      weightKg: weight,
                      activity: activity,
                      goal: goal,
                    ),
                  );
                  final where =
                      '$age y, $weight kg, $height cm, $sex, '
                      '${activity.name}, ${goal.name}';
                  expect(
                    t.caloriesKcal,
                    greaterThanOrEqualTo(t.floorKcal),
                    reason: where,
                  );
                  expect(
                    [t.proteinG, t.carbsG, t.fatG, t.waterL],
                    everyElement(greaterThanOrEqualTo(0)),
                    reason: where,
                  );
                  expect(
                    _macroKcal(t),
                    closeTo(t.caloriesKcal, 2),
                    reason: where,
                  );
                  checked++;
                }
              }
            }
          }
        }
      }
      expect(checked, 9000);
    });
  });

  group('age from the birth date', () {
    final born = DateTime(2000, 6, 15);

    test('counts the birthday itself', () {
      expect(ageOn(born, DateTime(2026, 6, 15)), 26);
    });

    test('is a year less the day before', () {
      expect(ageOn(born, DateTime(2026, 6, 14)), 25);
    });

    test('ignores the time of day', () {
      expect(ageOn(DateTime(2000, 6, 15, 23, 59), DateTime(2026, 6, 15)), 26);
    });

    test('someone born on 29 February turns older on 1 March', () {
      final leapDay = DateTime(2004, 2, 29);

      expect(ageOn(leapDay, DateTime(2027, 2, 28)), 22);
      expect(ageOn(leapDay, DateTime(2027, 3, 1)), 23);
      expect(ageOn(leapDay, DateTime(2028, 2, 29)), 24);
    });
  });

  test('targets record the formula version', () {
    expect(_python(GoalType.maintain, ActivityLevel.active).version, 'v1');
  });
}
