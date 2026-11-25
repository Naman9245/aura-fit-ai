import 'dart:math' as math;

import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/rounding.dart';

/// The calorie maths: a person's daily targets, worked out on the phone so
/// they need no network.
///
/// Every formula version stays in the code forever so goals worked out with
/// an older version are still explained the way they were reached:
///
/// * [formulaV1]: ported from the FastAPI backend's `calculations.py` with a
///   safe calorie floor (1,200 kcal for women, 1,500 kcal for men), non-negative
///   carbs, and age from the birth date.
/// * [formulaV2]: protein from an adjusted weight above a BMI of 30, a deficit
///   scaled to maintenance (20% capped at 500 kcal for fat loss, 10% capped at
///   200 kcal for recomposition), and at least 0.5 g of fat per kg of adjusted
///   weight.
const formulaV1 = 'v1';
const formulaV2 = 'v2';

/// The version new goals are worked out with.
const formulaVersion = formulaV2;

/// The lowest daily calorie target for a woman.
const femaleFloorKcal = 1200;

/// The lowest daily calorie target for a man.
const maleFloorKcal = 1500;

/// The lowest target for someone who didn't give their sex: the higher of
/// the two, since eating too little is the risk a floor is there to stop.
const unknownSexFloorKcal = 1500;

/// Share of the calories that comes from fat, before the minimum or carb rule.
const fatShare = 0.25;

/// Minimum grams of fat per kg of adjusted weight in formula v2.
const minFatPerKg = 0.5;

/// Water a day per kg of body weight, in ml.
const waterMlPerKg = 35;

/// Extra water a day, in litres, for the two most active levels.
const activeExtraWaterL = 0.5;

/// What the targets are worked out from.
class TargetInputs {
  const TargetInputs({
    required this.age,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
  });

  /// Whole years, from [ageOn].
  final int age;

  /// Null when the person would rather not say.
  final Sex? sex;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final GoalType goal;
}

/// Someone's age in whole years on [today], born on [birthDate]. Only the
/// dates count, not the times.
///
/// Someone born on 29 February has their birthday on 1 March in other
/// years.
int ageOn(DateTime birthDate, DateTime today) {
  final hadBirthday =
      today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  return today.year - birthDate.year - (hadBirthday ? 0 : 1);
}

/// Body mass index, to 2 decimal places.
double bmi(double weightKg, double heightCm) {
  final heightM = heightCm / 100;
  return roundHalfEven(weightKg / (heightM * heightM), 2);
}

/// The weight that gives a BMI of 30 for [heightCm].
double bmi30WeightKg(double heightCm) {
  final heightM = heightCm / 100;
  return 30 * heightM * heightM;
}

/// The weight formula v2 works protein and minimum fat out from: the person's
/// own weight up to a BMI of 30, plus a quarter of anything above it, so
/// targets change smoothly across the threshold.
double effectiveWeightKg(double weightKg, double heightCm) {
  final w30 = bmi30WeightKg(heightCm);
  return weightKg <= w30 ? weightKg : w30 + 0.25 * (weightKg - w30);
}

/// Energy used at complete rest a day, in kcal, by the Mifflin–St Jeor
/// equation. Not rounded.
double bmrKcal({
  required double weightKg,
  required double heightCm,
  required int age,
  required Sex? sex,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return base + sexOffsetKcal(sex);
}

/// The last term of the Mifflin–St Jeor equation. With no sex given, it is
/// halfway between the two.
int sexOffsetKcal(Sex? sex) => switch (sex) {
  Sex.male => 5,
  Sex.female => -161,
  null => -78,
};

/// How much more than resting energy a day takes at this activity level.
double activityMultiplier(ActivityLevel activity) => switch (activity) {
  ActivityLevel.sedentary => 1.2,
  ActivityLevel.lightlyActive => 1.375,
  ActivityLevel.active => 1.55,
  ActivityLevel.athlete => 1.725,
};

/// Fixed kcal a day added to (or taken from) maintenance in formula v1.
int goalAdjustmentKcal(GoalType goal) => switch (goal) {
  GoalType.gainMuscle => 300,
  GoalType.loseFat => -500,
  GoalType.maintain => 0,
  GoalType.recomposition => -200,
  GoalType.performance => 250,
};

/// Kcal a day added to (or taken from) [maintenanceKcal] in formula v2:
/// losing fat takes 20% off (at most 500 kcal), recomposition takes 10% off
/// (at most 200 kcal), and surpluses stay unchanged.
double goalAdjustmentV2Kcal(GoalType goal, double maintenanceKcal) =>
    switch (goal) {
      GoalType.gainMuscle => 300,
      GoalType.loseFat => -math.min(500.0, maintenanceKcal * 0.20),
      GoalType.maintain => 0,
      GoalType.recomposition => -math.min(200.0, maintenanceKcal * 0.10),
      GoalType.performance => 250,
    };

/// Grams of protein a day per kg of body weight for this goal.
double proteinPerKg(GoalType goal) => switch (goal) {
  GoalType.gainMuscle => 2.2,
  GoalType.loseFat => 1.8,
  GoalType.maintain => 1.6,
  GoalType.recomposition => 2.0,
  GoalType.performance => 1.8,
};

/// The calorie floor for [sex].
int calorieFloorKcal(Sex? sex) => switch (sex) {
  Sex.female => femaleFloorKcal,
  Sex.male => maleFloorKcal,
  null => unknownSexFloorKcal,
};

/// The daily step target for this activity level.
int dailySteps(ActivityLevel activity) => switch (activity) {
  ActivityLevel.sedentary => 8000,
  ActivityLevel.lightlyActive => 9000,
  ActivityLevel.active => 11000,
  ActivityLevel.athlete => 13000,
};

/// Daily targets, with every step of the working, so the app can show how
/// they were reached.
class Targets {
  const Targets({
    required this.version,
    required this.inputs,
    required this.bmi,
    required this.effectiveWeightKg,
    required this.adjustedWeightApplied,
    required this.bmrKcal,
    required this.maintenanceKcal,
    required this.adjustmentKcal,
    required this.unflooredKcal,
    required this.floorKcal,
    required this.floorApplied,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.minFatG,
    required this.fatFloorApplied,
    required this.carbRuleApplied,
    required this.proteinCutApplied,
    required this.waterL,
    required this.steps,
  });

  final String version;
  final TargetInputs inputs;

  /// To 2 decimal places.
  final double bmi;

  /// The weight protein (and v2's fat minimum) came from, to 1 decimal place.
  final double effectiveWeightKg;

  /// Whether [effectiveWeightKg] was lowered from [TargetInputs.weightKg].
  final bool adjustedWeightApplied;

  /// Resting energy, to 2 decimal places.
  final double bmrKcal;

  /// Energy used on a normal day at this activity level, to 2 places.
  final double maintenanceKcal;

  /// Kcal added to or taken from maintenance for the goal, to 2 places.
  final double adjustmentKcal;

  /// Maintenance plus the goal's adjustment, before the floor, to 2 places.
  final double unflooredKcal;

  /// The safe minimum for this person.
  final int floorKcal;

  /// Whether the target was raised to the safe minimum.
  final bool floorApplied;

  /// The daily calorie target, to 2 decimal places.
  final double caloriesKcal;

  /// Grams a day, to 1 decimal place.
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// The lowest fat target allowed by this formula, to 1 decimal place.
  final double minFatG;

  /// Whether fat was held at [minFatG] because 25% of calories was lower, or
  /// because carbs ran out.
  final bool fatFloorApplied;

  /// Whether carbs were cut to zero so protein and fat could fit.
  final bool carbRuleApplied;

  /// Whether protein had to give way after carbs and fat hit their floors.
  final bool proteinCutApplied;

  /// Litres a day, to 2 decimal places.
  final double waterL;
  final int steps;
}

/// Works out the daily targets for [inputs] with the current formula ([v2]).
Targets calculateTargets(TargetInputs inputs) => calculateTargetsV2(inputs);

/// Works out the daily targets with [version], or returns null when [version]
/// comes from a newer app build this phone doesn't know yet.
Targets? calculateTargetsForVersion(String version, TargetInputs inputs) =>
    switch (version) {
      formulaV1 => calculateTargetsV1(inputs),
      formulaV2 => calculateTargetsV2(inputs),
      _ => null,
    };

/// Works out the daily targets with formula v1 (kept forever for v1 goals).
Targets calculateTargetsV1(TargetInputs inputs) {
  final weight = inputs.weightKg;
  final bmr = bmrKcal(
    weightKg: weight,
    heightCm: inputs.heightCm,
    age: inputs.age,
    sex: inputs.sex,
  );
  final maintenance = bmr * activityMultiplier(inputs.activity);
  final adjustment = goalAdjustmentKcal(inputs.goal).toDouble();
  final unfloored = maintenance + adjustment;
  final floor = calorieFloorKcal(inputs.sex);
  final floorApplied = unfloored < floor;
  final calories = floorApplied ? floor.toDouble() : unfloored;

  var protein = proteinPerKg(inputs.goal) * weight;
  var fat = (calories * fatShare) / 9;
  var carbs = (calories - (protein * 4) - (fat * 9)) / 4;
  final carbRuleApplied = carbs < 0;
  var proteinCut = false;
  if (carbRuleApplied) {
    carbs = 0;
    fat = (calories - protein * 4) / 9;
    if (fat < 0) {
      fat = 0;
      protein = calories / 4;
      proteinCut = true;
    }
  }

  final water = _waterLitres(weight, inputs.activity);

  return Targets(
    version: formulaV1,
    inputs: inputs,
    bmi: bmi(weight, inputs.heightCm),
    effectiveWeightKg: roundHalfEven(weight, 1),
    adjustedWeightApplied: false,
    bmrKcal: roundHalfEven(bmr, 2),
    maintenanceKcal: roundHalfEven(maintenance, 2),
    adjustmentKcal: roundHalfEven(adjustment, 2),
    unflooredKcal: roundHalfEven(unfloored, 2),
    floorKcal: floor,
    floorApplied: floorApplied,
    caloriesKcal: roundHalfEven(calories, 2),
    proteinG: roundHalfEven(protein, 1),
    carbsG: roundHalfEven(carbs, 1),
    fatG: roundHalfEven(fat, 1),
    minFatG: 0,
    fatFloorApplied: false,
    carbRuleApplied: carbRuleApplied,
    proteinCutApplied: proteinCut,
    waterL: roundHalfEven(water, 2),
    steps: dailySteps(inputs.activity),
  );
}

/// Works out the daily targets with formula v2 (PRD A7).
Targets calculateTargetsV2(TargetInputs inputs) {
  final weight = inputs.weightKg;
  final w30 = bmi30WeightKg(inputs.heightCm);
  final adjustedWeight = weight > w30;
  final effWeight = effectiveWeightKg(weight, inputs.heightCm);

  final bmr = bmrKcal(
    weightKg: weight,
    heightCm: inputs.heightCm,
    age: inputs.age,
    sex: inputs.sex,
  );
  final maintenance = bmr * activityMultiplier(inputs.activity);
  final adjustment = goalAdjustmentV2Kcal(inputs.goal, maintenance);
  final unfloored = maintenance + adjustment;
  final floor = calorieFloorKcal(inputs.sex);
  final floorApplied = unfloored < floor;
  final calories = floorApplied ? floor.toDouble() : unfloored;

  var protein = proteinPerKg(inputs.goal) * effWeight;
  final minFat = minFatPerKg * effWeight;
  final quarterFat = (calories * fatShare) / 9;
  var fat = math.max(minFat, quarterFat);
  var fatFloorApplied = quarterFat < minFat;
  var carbs = (calories - (protein * 4) - (fat * 9)) / 4;
  final carbRuleApplied = carbs < 0;
  var proteinCut = false;
  if (carbRuleApplied) {
    carbs = 0;
    fat = (calories - protein * 4) / 9;
    if (fat < minFat) {
      fat = math.min(minFat, calories / 9);
      fatFloorApplied = true;
      protein = math.max(0.0, (calories - fat * 9) / 4);
      proteinCut = true;
    }
  }

  final water = _waterLitres(weight, inputs.activity);

  return Targets(
    version: formulaV2,
    inputs: inputs,
    bmi: bmi(weight, inputs.heightCm),
    effectiveWeightKg: roundHalfEven(effWeight, 1),
    adjustedWeightApplied: adjustedWeight,
    bmrKcal: roundHalfEven(bmr, 2),
    maintenanceKcal: roundHalfEven(maintenance, 2),
    adjustmentKcal: roundHalfEven(adjustment, 2),
    unflooredKcal: roundHalfEven(unfloored, 2),
    floorKcal: floor,
    floorApplied: floorApplied,
    caloriesKcal: roundHalfEven(calories, 2),
    proteinG: roundHalfEven(protein, 1),
    carbsG: roundHalfEven(carbs, 1),
    fatG: roundHalfEven(fat, 1),
    minFatG: roundHalfEven(minFat, 1),
    fatFloorApplied: fatFloorApplied,
    carbRuleApplied: carbRuleApplied,
    proteinCutApplied: proteinCut,
    waterL: roundHalfEven(water, 2),
    steps: dailySteps(inputs.activity),
  );
}

double _waterLitres(double weightKg, ActivityLevel activity) {
  var water = (weightKg * waterMlPerKg) / 1000;
  if (activity == ActivityLevel.active || activity == ActivityLevel.athlete) {
    water += activeExtraWaterL;
  }
  return water;
}
