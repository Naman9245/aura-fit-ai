import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/rounding.dart';

/// The calorie maths: a person's daily targets, worked out on the phone so
/// they need no network.
///
/// This is formula v1, ported from the FastAPI backend's `calculations.py`
/// with three fixes:
///
/// * Calories never go below a safe minimum: 1,200 kcal for women and
///   1,500 kcal for men. Before, a 50 kg woman who sits most of the day and
///   wants to lose fat was told to eat 889 kcal.
/// * Carbs never go negative. When protein and fat would take up every
///   calorie, fat gives way first, then protein.
/// * Age comes from the birth date, so it is right on every day of the year.
///
/// Everything else gives exactly the numbers the Python did, rounded the
/// same way; `test/services/python_parity_test.dart` checks it against what
/// the Python returned.
///
/// When the formula changes, the old version stays: a goal records the
/// version it was worked out with, and is explained with that version.
const formulaVersion = 'v1';

/// The lowest daily calorie target for a woman.
const femaleFloorKcal = 1200;

/// The lowest daily calorie target for a man.
const maleFloorKcal = 1500;

/// The lowest target for someone who didn't give their sex: the higher of
/// the two, since eating too little is the risk a floor is there to stop.
const unknownSexFloorKcal = 1500;

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

/// Kcal a day added to (or taken from) maintenance for this goal.
int goalAdjustmentKcal(GoalType goal) => switch (goal) {
  GoalType.gainMuscle => 300,
  GoalType.loseFat => -500,
  GoalType.maintain => 0,
  GoalType.recomposition => -200,
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

/// Share of the calories that comes from fat, before the carb rule.
const fatShare = 0.25;

/// Water a day per kg of body weight, in ml.
const waterMlPerKg = 35;

/// Extra water a day, in litres, for the two most active levels.
const activeExtraWaterL = 0.5;

/// Daily targets, with every step of the working, so the app can show how
/// they were reached. Values are rounded as the Python rounded them.
class Targets {
  const Targets({
    required this.inputs,
    required this.bmi,
    required this.bmrKcal,
    required this.maintenanceKcal,
    required this.unflooredKcal,
    required this.floorKcal,
    required this.floorApplied,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.carbRuleApplied,
    required this.waterL,
    required this.steps,
  });

  final TargetInputs inputs;

  /// To 2 decimal places.
  final double bmi;

  /// Resting energy, to 2 decimal places.
  final double bmrKcal;

  /// Energy used on a normal day at this activity level, to 2 places.
  final double maintenanceKcal;

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

  /// Whether fat (and perhaps protein) was cut so carbs didn't go negative.
  final bool carbRuleApplied;

  /// Litres a day, to 2 decimal places.
  final double waterL;
  final int steps;

  String get version => formulaVersion;
}

/// Works out the daily targets for [inputs] with formula v1.
Targets calculateTargets(TargetInputs inputs) {
  final weight = inputs.weightKg;
  final bmr = bmrKcal(
    weightKg: weight,
    heightCm: inputs.heightCm,
    age: inputs.age,
    sex: inputs.sex,
  );
  final maintenance = bmr * activityMultiplier(inputs.activity);
  final unfloored = maintenance + goalAdjustmentKcal(inputs.goal);
  final floor = calorieFloorKcal(inputs.sex);
  final floorApplied = unfloored < floor;
  final calories = floorApplied ? floor.toDouble() : unfloored;

  var protein = proteinPerKg(inputs.goal) * weight;
  var fat = (calories * fatShare) / 9;
  var carbs = (calories - (protein * 4) - (fat * 9)) / 4;
  final carbRuleApplied = carbs < 0;
  if (carbRuleApplied) {
    carbs = 0;
    fat = (calories - protein * 4) / 9;
    if (fat < 0) {
      fat = 0;
      protein = calories / 4;
    }
  }

  var water = (weight * waterMlPerKg) / 1000;
  if (inputs.activity == ActivityLevel.active ||
      inputs.activity == ActivityLevel.athlete) {
    water += activeExtraWaterL;
  }

  return Targets(
    inputs: inputs,
    bmi: bmi(weight, inputs.heightCm),
    bmrKcal: roundHalfEven(bmr, 2),
    maintenanceKcal: roundHalfEven(maintenance, 2),
    unflooredKcal: roundHalfEven(unfloored, 2),
    floorKcal: floor,
    floorApplied: floorApplied,
    caloriesKcal: roundHalfEven(calories, 2),
    proteinG: roundHalfEven(protein, 1),
    carbsG: roundHalfEven(carbs, 1),
    fatG: roundHalfEven(fat, 1),
    carbRuleApplied: carbRuleApplied,
    waterL: roundHalfEven(water, 2),
    steps: dailySteps(inputs.activity),
  );
}
