import 'dart:math' as math;

import 'package:aurafit/core/format.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/targets.dart';
import 'package:flutter/foundation.dart';

/// Tone for dashboard feedback. Never red and never celebratory for eating
/// below the safe floor (PRD D4, Experience rules).
enum CalmTone { neutral, amber }

@immutable
class CalmFeedback {
  const CalmFeedback({required this.tone, required this.message});

  final CalmTone tone;
  final String message;

  bool get isAmber => tone == CalmTone.amber;
}

/// One deterministic food suggestion to help close today's protein gap (PRD C5).
@immutable
class ProteinIdea {
  const ProteinIdea({
    required this.dish,
    required this.serving,
    required this.proteinG,
    required this.kcal,
    required this.searchQuery,
  });

  final String dish;
  final String serving;
  final int proteinG;
  final int kcal;
  final String searchQuery;
}

@immutable
class ProteinGuidance {
  const ProteinGuidance({
    required this.proteinLeftG,
    required this.ideas,
    this.floorNote,
  });

  final int proteinLeftG;
  final List<ProteinIdea> ideas;
  final String? floorNote;
}

/// Evaluates today's (or yesterday's) intake against the person's target,
/// maintenance energy and safe floor, without red alarms or guilt (PRD D4).
CalmFeedback evaluateDayFeedback({
  required double eatenKcal,
  required int targetKcal,
  required double? maintenanceKcal,
  required Sex? sex,
  required bool isToday,
  required int currentHour,
  required int mealCount,
}) {
  final eaten = eatenKcal.round();
  final floor = calorieFloorKcal(sex);

  // Over target: calm amber with how the day compares to maintenance. Never red.
  if (eaten > targetKcal) {
    final over = eaten - targetKcal;
    if (maintenanceKcal != null) {
      final maint = maintenanceKcal.round();
      if (eaten <= maint) {
        return CalmFeedback(
          tone: CalmTone.amber,
          message:
              '${formatWhole(over)} kcal over target, still below what your '
              'body uses (${formatWhole(maint)} kcal). One day doesn\'t '
              'change the week.',
        );
      }
      final overMaint = eaten - maint;
      return CalmFeedback(
        tone: CalmTone.amber,
        message:
            '${formatWhole(over)} kcal over target (${formatWhole(overMaint)} '
            'kcal above maintenance). One day doesn\'t change the week — '
            'check your 7-day average.',
      );
    }
    return CalmFeedback(
      tone: CalmTone.amber,
      message:
          '${formatWhole(over)} kcal over target. One day doesn\'t change the '
          'week — check your 7-day average.',
    );
  }

  // Evening or completed yesterday far under target / below safe floor:
  // ask calmly whether a meal is missing; never praise undereating.
  final checkUnderEating =
      (isToday && currentHour >= 19) || (!isToday && mealCount > 0);
  if (checkUnderEating &&
      (eaten < floor || eaten < (targetKcal * 0.65).round())) {
    if (mealCount == 0) {
      return const CalmFeedback(
        tone: CalmTone.amber,
        message:
            'Nothing is logged yet for this evening — is a meal still to be '
            'added?',
      );
    }
    return CalmFeedback(
      tone: CalmTone.amber,
      message:
          'Looks low so far (${formatWhole(eaten)} kcal) — is a meal missing? '
          'Staying at or above ${formatWhole(floor)} kcal keeps your plan safe.',
    );
  }

  if (mealCount == 0) {
    return CalmFeedback(
      tone: CalmTone.neutral,
      message:
          'Target: ${formatWhole(targetKcal)} kcal. Log a meal by search, '
          'text or repeat below.',
    );
  }

  final left = math.max(0, targetKcal - eaten);
  if (left <= 40) {
    return CalmFeedback(
      tone: CalmTone.neutral,
      message:
          'Close to your ${formatWhole(targetKcal)} kcal target for the day.',
    );
  }
  return CalmFeedback(
    tone: CalmTone.neutral,
    message: '${formatWhole(left)} kcal left for the day.',
  );
}

/// Deterministic, offline rule-based protein ideas tailored to [dietType] and
/// remaining protein, while respecting the daily safe calorie floor (PRD C5).
ProteinGuidance buildProteinGuidance({
  required DietType? dietType,
  required int targetProteinG,
  required double eatenProteinG,
  required int targetKcal,
  required double eatenKcal,
  required Sex? sex,
}) {
  final leftG = math.max(0, targetProteinG - eatenProteinG.round());
  if (leftG <= 5) {
    return const ProteinGuidance(proteinLeftG: 0, ideas: []);
  }

  final pool = switch (dietType) {
    DietType.vegan => _veganPool,
    DietType.egg => _eggPool,
    DietType.nonVeg => _nonVegPool,
    DietType.veg || null => _vegPool,
  };

  // Pick ideas that best fit the remaining protein gap without overshooting
  // wildly when only 10-15 g is left.
  final sorted = [...pool]
    ..sort((a, b) {
      final diffA = (a.proteinG - math.min(leftG, 30)).abs();
      final diffB = (b.proteinG - math.min(leftG, 30)).abs();
      return diffA.compareTo(diffB);
    });

  final floor = calorieFloorKcal(sex);
  final effectiveTarget = math.max(targetKcal, floor);
  final kcalNeededForFloor = math.max(0, floor - eatenKcal.round());
  final String? floorNote = kcalNeededForFloor > 0
      ? 'You also have at least ${formatWhole(kcalNeededForFloor)} kcal before '
            'reaching your '
            '${formatWhole(effectiveTarget >= floor ? floor : effectiveTarget)} '
            'kcal safe minimum.'
      : null;

  return ProteinGuidance(
    proteinLeftG: leftG,
    ideas: sorted.take(3).toList(growable: false),
    floorNote: floorNote,
  );
}

const _vegPool = <ProteinIdea>[
  ProteinIdea(
    dish: 'Soya chunks stir-fry',
    serving: '1 katori (50 g dry cooked)',
    proteinG: 25,
    kcal: 215,
    searchQuery: 'Dry Soya Chunks Stir-Fry',
  ),
  ProteinIdea(
    dish: 'Low-fat paneer bhurji',
    serving: '1 katori (130 g)',
    proteinG: 21,
    kcal: 203,
    searchQuery: 'Low-Fat Paneer Bhurji',
  ),
  ProteinIdea(
    dish: 'Greek yogurt / hung curd',
    serving: '1 cup (150 g)',
    proteinG: 14,
    kcal: 115,
    searchQuery: 'Greek Yogurt',
  ),
  ProteinIdea(
    dish: 'Roasted chana or sattu drink',
    serving: '45 g serving',
    proteinG: 10,
    kcal: 165,
    searchQuery: 'Sattu',
  ),
];

const _veganPool = <ProteinIdea>[
  ProteinIdea(
    dish: 'Dry soya chunks stir-fry',
    serving: '1 katori (50 g dry cooked)',
    proteinG: 25,
    kcal: 215,
    searchQuery: 'Dry Soya Chunks Stir-Fry',
  ),
  ProteinIdea(
    dish: 'Tofu bhurji',
    serving: '1 katori (150 g)',
    proteinG: 18,
    kcal: 204,
    searchQuery: 'Tofu Bhurji',
  ),
  ProteinIdea(
    dish: 'Boiled kala chana / chickpeas',
    serving: '1 katori (150 g)',
    proteinG: 13,
    kcal: 246,
    searchQuery: 'Boiled Chickpeas',
  ),
  ProteinIdea(
    dish: 'Roasted chana / Bihar sattu',
    serving: '45 g serving',
    proteinG: 10,
    kcal: 165,
    searchQuery: 'Sattu',
  ),
];

const _eggPool = <ProteinIdea>[
  ProteinIdea(
    dish: 'Boiled egg whites',
    serving: '4 whites (132 g)',
    proteinG: 14,
    kcal: 69,
    searchQuery: 'Boiled Egg White',
  ),
  ProteinIdea(
    dish: 'Masala omelette / 2 boiled eggs',
    serving: '2 whole eggs',
    proteinG: 13,
    kcal: 155,
    searchQuery: 'Boiled Whole Egg',
  ),
  ProteinIdea(
    dish: 'Soya chunks stir-fry',
    serving: '1 katori',
    proteinG: 25,
    kcal: 215,
    searchQuery: 'Dry Soya Chunks Stir-Fry',
  ),
  ProteinIdea(
    dish: 'Low-fat paneer bhurji',
    serving: '1 katori',
    proteinG: 21,
    kcal: 203,
    searchQuery: 'Low-Fat Paneer Bhurji',
  ),
];

const _nonVegPool = <ProteinIdea>[
  ProteinIdea(
    dish: 'Poached / grilled chicken breast',
    serving: '150 g cooked',
    proteinG: 44,
    kcal: 267,
    searchQuery: 'Grilled / Tandoori Chicken Breast',
  ),
  ProteinIdea(
    dish: 'Tawa fish fry / fish curry',
    serving: '100 g fillet',
    proteinG: 22,
    kcal: 198,
    searchQuery: 'Tawa Fish Fry',
  ),
  ProteinIdea(
    dish: 'Boiled whole eggs',
    serving: '2 eggs',
    proteinG: 13,
    kcal: 155,
    searchQuery: 'Boiled Whole Egg',
  ),
  ProteinIdea(
    dish: 'Boiled egg whites',
    serving: '3 whites',
    proteinG: 11,
    kcal: 52,
    searchQuery: 'Boiled Egg White',
  ),
];
