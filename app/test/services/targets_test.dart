import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/rounding.dart';
import 'package:aurafit/services/targets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The profile the Python tests used: 70 kg, 175 cm, 25 years.
Targets _python(GoalType goal, ActivityLevel activity, {Sex? sex = Sex.male}) =>
    calculateTargetsV1(
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
  group('formula v1 (ported from test_calculations.py, kept forever)', () {
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

    test('a fat loss goal is a 500 calorie deficit in v1', () {
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

    test('the 889 kcal case is raised to 1,200 kcal for a woman in v1', () {
      final t = calculateTargetsV1(
        const TargetInputs(
          age: 30,
          sex: Sex.female,
          heightCm: 155,
          weightKg: 50,
          activity: ActivityLevel.sedentary,
          goal: GoalType.loseFat,
        ),
      );

      expect(t.unflooredKcal, 889.3);
      expect(t.caloriesKcal, 1200);
      expect(t.floorApplied, isTrue);
      expect(t.version, 'v1');
    });

    test(
      'no target is negative or below the floor across 9,000 profiles (v1)',
      () {
        var checked = 0;
        for (final age in [18, 30, 50, 75, 100]) {
          for (final weight in [30.0, 50.0, 80.0, 120.0, 180.0, 250.0]) {
            for (final height in [120.0, 150.0, 175.0, 200.0, 230.0]) {
              for (final sex in [...Sex.values, null]) {
                for (final activity in ActivityLevel.values) {
                  for (final goal in GoalType.values) {
                    final t = calculateTargetsV1(
                      TargetInputs(
                        age: age,
                        sex: sex,
                        heightCm: height,
                        weightKg: weight,
                        activity: activity,
                        goal: goal,
                      ),
                    );
                    expect(t.caloriesKcal, greaterThanOrEqualTo(t.floorKcal));
                    expect([
                      t.proteinG,
                      t.carbsG,
                      t.fatG,
                      t.waterL,
                    ], everyElement(greaterThanOrEqualTo(0)));
                    expect(_macroKcal(t), closeTo(t.caloriesKcal, 2));
                    checked++;
                  }
                }
              }
            }
          }
        }
        expect(checked, 9000);
      },
    );
  });

  group('formula v2 (A7)', () {
    test('uses an adjusted weight above BMI 30 and changes smoothly at 30', () {
      // At 170 cm, BMI 30 is 30 × 1.7² = 86.7 kg.
      expect(bmi30WeightKg(170), closeTo(86.7, 1e-9));
      expect(effectiveWeightKg(86.7, 170), closeTo(86.7, 1e-9));

      // Just below and just above BMI 30: no sudden jump.
      final below = calculateTargetsV2(
        const TargetInputs(
          age: 28,
          sex: Sex.male,
          heightCm: 170,
          weightKg: 86.6,
          activity: ActivityLevel.lightlyActive,
          goal: GoalType.loseFat,
        ),
      );
      final above = calculateTargetsV2(
        const TargetInputs(
          age: 28,
          sex: Sex.male,
          heightCm: 170,
          weightKg: 86.8,
          activity: ActivityLevel.lightlyActive,
          goal: GoalType.loseFat,
        ),
      );
      expect(below.adjustedWeightApplied, isFalse);
      expect(above.adjustedWeightApplied, isTrue);
      expect((above.proteinG - below.proteinG).abs(), lessThan(0.5));

      // A 150 kg person at 170 cm isn't told to eat 270 g of protein.
      final heavy = calculateTargetsV2(
        const TargetInputs(
          age: 35,
          sex: Sex.male,
          heightCm: 170,
          weightKg: 150,
          activity: ActivityLevel.sedentary,
          goal: GoalType.loseFat,
        ),
      );
      // w_eff = 86.7 + 0.25 × (150 - 86.7) = 102.525 kg → 184.5 g protein.
      expect(heavy.effectiveWeightKg, 102.5);
      expect(heavy.proteinG, 184.5);
    });

    test('losing fat takes 20% off maintenance, capped at 500 kcal', () {
      // 50 kg woman, 1,389.3 kcal maintenance → loses 277.86 kcal, then floor.
      final small = calculateTargetsV2(
        const TargetInputs(
          age: 30,
          sex: Sex.female,
          heightCm: 155,
          weightKg: 50,
          activity: ActivityLevel.sedentary,
          goal: GoalType.loseFat,
        ),
      );
      expect(small.maintenanceKcal, 1389.3);
      expect(small.adjustmentKcal, closeTo(-277.86, 0.01));
      expect(small.unflooredKcal, closeTo(1111.44, 0.01));
      expect(small.caloriesKcal, 1200);
      expect(small.floorApplied, isTrue);

      // High maintenance (> 2,500 kcal) caps the deficit at 500 kcal.
      final tall = calculateTargetsV2(
        const TargetInputs(
          age: 25,
          sex: Sex.male,
          heightCm: 185,
          weightKg: 85,
          activity: ActivityLevel.active,
          goal: GoalType.loseFat,
        ),
      );
      expect(tall.maintenanceKcal, greaterThan(2500));
      expect(tall.adjustmentKcal, -500);
    });

    test('recomposition takes 10% off maintenance, capped at 200 kcal', () {
      final smaller = calculateTargetsV2(
        const TargetInputs(
          age: 28,
          sex: Sex.female,
          heightCm: 160,
          weightKg: 55,
          activity: ActivityLevel.lightlyActive,
          goal: GoalType.recomposition,
        ),
      );
      expect(smaller.maintenanceKcal, lessThan(2000));
      expect(
        smaller.adjustmentKcal,
        closeTo(-smaller.maintenanceKcal * 0.10, 0.02),
      );
    });

    test('fat never drops below 0.5 g per kg of adjusted weight across 9,000 profiles', () {
      var checked = 0;
      for (final age in [18, 30, 50, 75, 100]) {
        for (final weight in [30.0, 50.0, 80.0, 120.0, 180.0, 250.0]) {
          for (final height in [120.0, 150.0, 175.0, 200.0, 230.0]) {
            for (final sex in [...Sex.values, null]) {
              for (final activity in ActivityLevel.values) {
                for (final goal in GoalType.values) {
                  final t = calculateTargetsV2(
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
                  final expectedMinFat = roundHalfEven(
                    minFatPerKg * effectiveWeightKg(weight, height),
                    1,
                  );
                  expect(
                    t.caloriesKcal,
                    greaterThanOrEqualTo(t.floorKcal),
                    reason: where,
                  );
                  expect(
                    t.fatG,
                    greaterThanOrEqualTo(expectedMinFat),
                    reason: where,
                  );
                  expect(
                    [t.proteinG, t.carbsG, t.waterL],
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

    test(
      'calculateTargetsForVersion keeps v1, v2 and returns null for unknown',
      () {
        const inputs = TargetInputs(
          age: 30,
          sex: Sex.female,
          heightCm: 155,
          weightKg: 50,
          activity: ActivityLevel.sedentary,
          goal: GoalType.loseFat,
        );
        expect(calculateTargetsForVersion('v1', inputs)?.unflooredKcal, 889.3);
        expect(
          calculateTargetsForVersion('v2', inputs)?.unflooredKcal,
          1111.44,
        );
        expect(calculateTargetsForVersion('v99', inputs), isNull);
      },
    );
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

  test('new targets default to formula v2', () {
    expect(
      calculateTargets(
        const TargetInputs(
          age: 25,
          sex: Sex.male,
          heightCm: 175,
          weightKg: 70,
          activity: ActivityLevel.active,
          goal: GoalType.maintain,
        ),
      ).version,
      'v2',
    );
  });
}
