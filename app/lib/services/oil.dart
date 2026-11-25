import 'dart:math' as math;

import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/rounding.dart';

/// Nutrients for a chosen portion and oil level (PRD N9).
class CalculatedNutrients {
  const CalculatedNutrients({
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double grams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
}

/// Whether a food's baseline recipe has no added oil or ghee (such as plain
/// phulka, steamed rice, boiled egg or raw staples).
bool isNoOilBaseline({required String assumption, required String source}) {
  if (source != 'recipe') return true;
  final lower = assumption.toLowerCase();
  return lower.contains('no ghee') ||
      lower.contains('no oil') ||
      lower.contains('steamed') ||
      lower.contains('boiled');
}

/// Default oil choice when picking [assumption] / [source]: `'low'` when the
/// baseline recipe has no added oil or ghee, `'home'` for cooked dishes.
OilLevel defaultOilLevel({
  required String assumption,
  required String source,
}) => isNoOilBaseline(assumption: assumption, source: source)
    ? OilLevel.low
    : OilLevel.home;

/// Works out the nutrients for [grams] of a food at [oilLevel].
///
/// * When the baseline has no added oil or ghee (such as `"30 g wheat atta,
///   no ghee"`), [OilLevel.low] keeps the baseline, [OilLevel.home] adds half
///   a teaspoon of ghee/oil per 100 g (~3.5 g/100 g, ~2.2 g on a 60 g pair of
///   phulkas), and [OilLevel.extra] adds 7.5 g/100 g (~1 tsp per phulka).
/// * When the baseline is already home-cooked with oil, [OilLevel.home] keeps
///   the baseline, [OilLevel.low] trims up to 3.0 g of cooking fat per 100 g
///   (never below 0.5 g/100 g natural fat), and [OilLevel.extra] adds 6.0 g
///   of restaurant/extra fat per 100 g.
///
/// Each gram of oil or ghee changes fat by 1 g and energy by 9 kcal.
CalculatedNutrients calculateFoodNutrients({
  required double kcalPer100g,
  required double proteinGPer100g,
  required double carbsGPer100g,
  required double fatGPer100g,
  required String assumption,
  required String source,
  required double grams,
  required OilLevel? oilLevel,
}) {
  final scale = grams / 100.0;
  final baseKcal = kcalPer100g * scale;
  final protein = proteinGPer100g * scale;
  final carbs = carbsGPer100g * scale;
  final baseFat = fatGPer100g * scale;

  final noOilBase = isNoOilBaseline(assumption: assumption, source: source);
  final deltaFatPer100g = switch ((oilLevel, noOilBase)) {
    (null, _) => 0.0,
    (OilLevel.low, true) => 0.0,
    (OilLevel.home, true) => source == 'recipe' ? 3.5 : 0.0,
    (OilLevel.extra, true) => 7.5,
    (OilLevel.low, false) => -math.min(3.0, math.max(0.0, fatGPer100g - 0.5)),
    (OilLevel.home, false) => 0.0,
    (OilLevel.extra, false) => 6.0,
  };

  final deltaFat = deltaFatPer100g * scale;
  final fat = math.max(0.0, baseFat + deltaFat);
  final actualDeltaFat = fat - baseFat;
  final kcal = math.max(0.0, baseKcal + actualDeltaFat * 9.0);

  return CalculatedNutrients(
    grams: roundHalfEven(grams, 1),
    kcal: roundHalfEven(kcal, 1),
    proteinG: roundHalfEven(protein, 1),
    carbsG: roundHalfEven(carbs, 1),
    fatG: roundHalfEven(fat, 1),
  );
}
