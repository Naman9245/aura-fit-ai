import 'dart:async';

import 'package:aurafit/core/config.dart';
import 'package:aurafit/data/food_repository.dart';
import 'package:aurafit/data/supabase_start.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/rounding.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const maxMealTextLength = 300;

enum ParseConfidence { high, medium, low }

/// Why AI text parsing fell back to offline search / manual quick-add (PRD N2).
enum MealParseFallbackReason {
  offline,
  dailyLimitReached,
  aiUnavailable,
  signedOut,
}

class MealParseFallbackException implements Exception {
  const MealParseFallbackException(this.reason);

  final MealParseFallbackReason reason;
}

/// Raw item returned by the `parse-meal` Edge Function before database
/// matching.
@immutable
class RawAiMealItem {
  const RawAiMealItem({
    required this.name,
    required this.searchQuery,
    required this.quantity,
    required this.unit,
    required this.oilLevel,
    required this.estimatedGrams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidence,
  });

  final String name;
  final String searchQuery;
  final double quantity;
  final String unit;
  final OilLevel oilLevel;
  final double estimatedGrams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final ParseConfidence confidence;

  factory RawAiMealItem.fromJson(Map<String, Object?> json) {
    final oilRaw = json['oil_level'] as String?;
    final confRaw = json['confidence'] as String?;
    return RawAiMealItem(
      name: (json['name'] as String? ?? '').trim(),
      searchQuery: (json['search_query'] as String? ?? '').trim(),
      quantity: ((json['quantity'] as num?) ?? 1).toDouble(),
      unit: (json['unit'] as String? ?? 'serving').trim().toLowerCase(),
      oilLevel: switch (oilRaw) {
        'low' => OilLevel.low,
        'extra' => OilLevel.extra,
        _ => OilLevel.home,
      },
      estimatedGrams: ((json['estimated_grams'] as num?) ?? 100).toDouble(),
      kcal: ((json['kcal'] as num?) ?? 0).toDouble(),
      proteinG: ((json['protein_g'] as num?) ?? 0).toDouble(),
      carbsG: ((json['carbs_g'] as num?) ?? 0).toDouble(),
      fatG: ((json['fat_g'] as num?) ?? 0).toDouble(),
      confidence: switch (confRaw) {
        'high' => ParseConfidence.high,
        'low' => ParseConfidence.low,
        _ => ParseConfidence.medium,
      },
    );
  }
}

/// Editable draft item shown to the user before anything is saved (PRD N2).
///
/// When [matchedFood] is non-null, numbers come from the verified catalogue
/// ("the AI translates, the database counts"). When null, numbers are the AI's
/// estimate and the UI labels the item `"AI estimate, tap to adjust"`.
@immutable
class ParsedMealDraft {
  const ParsedMealDraft({
    required this.matchedFood,
    required this.name,
    required this.portionUnit,
    required this.portionCount,
    required this.oilLevel,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.confidence,
  });

  final FoodItem? matchedFood;
  final String name;
  final String portionUnit;
  final double portionCount;
  final OilLevel oilLevel;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final ParseConfidence confidence;

  bool get isVerifiedMatch => matchedFood != null;

  /// Recalculates nutrients when the user edits count or oil level on the
  /// confirmation screen.
  ParsedMealDraft adjust({double? count, OilLevel? oil, double? customKcal}) {
    final nextCount = (count ?? portionCount).clamp(0.25, 5000.0);
    final nextOil = oil ?? oilLevel;
    final food = matchedFood;
    if (food != null) {
      final calc = food.calculate(
        unit: portionUnit,
        count: nextCount,
        oilLevel: nextOil,
      );
      return ParsedMealDraft(
        matchedFood: food,
        name: name,
        portionUnit: portionUnit,
        portionCount: roundHalfEven(nextCount, 2),
        oilLevel: nextOil,
        grams: calc.grams,
        kcal: customKcal ?? calc.kcal,
        proteinG: calc.proteinG,
        carbsG: calc.carbsG,
        fatG: calc.fatG,
        confidence: confidence,
      );
    }

    // AI estimate: scale proportionally by count, and adjust oil at 9 kcal/g.
    final ratio = portionCount > 0 ? nextCount / portionCount : 1.0;
    final scaledGrams = (grams * ratio).clamp(1.0, 5000.0);
    final scaledProtein = proteinG * ratio;
    final scaledCarbs = carbsG * ratio;
    var scaledFat = fatG * ratio;
    var scaledKcal = kcal * ratio;

    if (nextOil != oilLevel) {
      final deltaPer100g = _oilStepGrams(nextOil) - _oilStepGrams(oilLevel);
      final deltaFat = deltaPer100g * (scaledGrams / 100.0);
      final newFat = (scaledFat + deltaFat).clamp(0.0, 500.0);
      scaledKcal = (scaledKcal + (newFat - scaledFat) * 9.0).clamp(
        0.0,
        10000.0,
      );
      scaledFat = newFat;
    }

    return ParsedMealDraft(
      matchedFood: null,
      name: name,
      portionUnit: portionUnit,
      portionCount: roundHalfEven(nextCount, 2),
      oilLevel: nextOil,
      grams: roundHalfEven(scaledGrams, 1),
      kcal: roundHalfEven(customKcal ?? scaledKcal, 1),
      proteinG: roundHalfEven(scaledProtein, 1),
      carbsG: roundHalfEven(scaledCarbs, 1),
      fatG: roundHalfEven(scaledFat, 1),
      confidence: confidence,
    );
  }

  static double _oilStepGrams(OilLevel level) => switch (level) {
    OilLevel.low => 0.0,
    OilLevel.home => 3.5,
    OilLevel.extra => 7.5,
  };
}

/// Server transport for `parse-meal`, abstract for offline & unit testing.
abstract interface class MealParseRemote {
  bool get isConfigured;
  Future<List<RawAiMealItem>> parseText(String text);
}

class SupabaseMealParseRemote implements MealParseRemote {
  SupabaseMealParseRemote([this._connect = startSupabase]);

  final Future<SupabaseClient> Function() _connect;
  static const _timeout = Duration(seconds: 15);

  @override
  bool get isConfigured => SupabaseConfig.isSet;

  @override
  Future<List<RawAiMealItem>> parseText(String text) async {
    if (!isConfigured) {
      throw const MealParseFallbackException(
        MealParseFallbackReason.aiUnavailable,
      );
    }
    final client = await _connect();
    if (client.auth.currentSession == null) {
      throw const MealParseFallbackException(MealParseFallbackReason.signedOut);
    }
    try {
      final res = await client.functions
          .invoke('parse-meal', method: HttpMethod.post, body: {'text': text})
          .timeout(_timeout);
      final data = res.data;
      if (data is! Map) {
        throw const MealParseFallbackException(
          MealParseFallbackReason.aiUnavailable,
        );
      }
      final rawItems = data['items'];
      if (rawItems is! List) return const [];
      return [
        for (final item in rawItems)
          if (item is Map)
            RawAiMealItem.fromJson(Map<String, Object?>.from(item)),
      ];
    } on TimeoutException {
      throw const MealParseFallbackException(
        MealParseFallbackReason.aiUnavailable,
      );
    } on FunctionException catch (error) {
      if (error.status == 401) {
        throw const MealParseFallbackException(
          MealParseFallbackReason.signedOut,
        );
      }
      if (error.status == 429) {
        throw const MealParseFallbackException(
          MealParseFallbackReason.dailyLimitReached,
        );
      }
      throw const MealParseFallbackException(
        MealParseFallbackReason.aiUnavailable,
      );
    } on Exception {
      throw const MealParseFallbackException(MealParseFallbackReason.offline);
    }
  }
}

/// Orchestrates AI text parsing with a circuit breaker and verified-catalogue
/// matching first (PRD N2, pages 10-11).
class MealTextParser {
  MealTextParser(this._foods, this._remote);

  final FoodRepository _foods;
  final MealParseRemote _remote;

  int _consecutiveFailures = 0;
  DateTime? _circuitOpenUntil;

  static const _breakerThreshold = 3;
  static const _breakerCooldown = Duration(minutes: 2);

  Future<List<ParsedMealDraft>> parse(String rawText) async {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return const [];
    final safeText = trimmed.length <= maxMealTextLength
        ? trimmed
        : trimmed.substring(0, maxMealTextLength);

    final now = clock.now();
    if (_circuitOpenUntil != null && now.isBefore(_circuitOpenUntil!)) {
      throw const MealParseFallbackException(
        MealParseFallbackReason.aiUnavailable,
      );
    }

    if (!_remote.isConfigured) {
      throw const MealParseFallbackException(
        MealParseFallbackReason.aiUnavailable,
      );
    }

    final List<RawAiMealItem> rawItems;
    try {
      rawItems = await _remote.parseText(safeText);
      _consecutiveFailures = 0;
      _circuitOpenUntil = null;
    } on MealParseFallbackException catch (error) {
      if (error.reason == MealParseFallbackReason.aiUnavailable ||
          error.reason == MealParseFallbackReason.offline) {
        _consecutiveFailures += 1;
        if (_consecutiveFailures >= _breakerThreshold) {
          _circuitOpenUntil = clock.now().add(_breakerCooldown);
        }
      }
      rethrow;
    }

    final catalogue = await _foods.allFoods();
    return [for (final item in rawItems) _matchOrEstimate(item, catalogue)];
  }

  ParsedMealDraft _matchOrEstimate(
    RawAiMealItem item,
    List<FoodItem> catalogue,
  ) {
    final match = _bestCatalogueMatch(item, catalogue);
    if (match != null) {
      final (unit, count) = _resolvePortion(match, item);
      final calc = match.calculate(
        unit: unit,
        count: count,
        oilLevel: item.oilLevel,
      );
      return ParsedMealDraft(
        matchedFood: match,
        name: match.name,
        portionUnit: unit,
        portionCount: roundHalfEven(count, 2),
        oilLevel: item.oilLevel,
        grams: calc.grams,
        kcal: calc.kcal,
        proteinG: calc.proteinG,
        carbsG: calc.carbsG,
        fatG: calc.fatG,
        confidence: item.confidence,
      );
    }

    final count = item.quantity > 0 ? item.quantity : 1.0;
    return ParsedMealDraft(
      matchedFood: null,
      name: item.name.isEmpty ? 'Meal item' : item.name,
      portionUnit: item.unit.isEmpty ? 'serving' : item.unit,
      portionCount: roundHalfEven(count, 2),
      oilLevel: item.oilLevel,
      grams: roundHalfEven(item.estimatedGrams.clamp(1.0, 5000.0), 1),
      kcal: roundHalfEven(item.kcal.clamp(0.0, 10000.0), 1),
      proteinG: roundHalfEven(item.proteinG.clamp(0.0, 500.0), 1),
      carbsG: roundHalfEven(item.carbsG.clamp(0.0, 1000.0), 1),
      fatG: roundHalfEven(item.fatG.clamp(0.0, 500.0), 1),
      confidence: item.confidence,
    );
  }

  static FoodItem? _bestCatalogueMatch(
    RawAiMealItem item,
    List<FoodItem> catalogue,
  ) {
    final queries = [
      if (item.searchQuery.isNotEmpty) item.searchQuery.toLowerCase(),
      if (item.name.isNotEmpty) item.name.toLowerCase(),
    ];
    for (final q in queries) {
      final qWords = _words(q);
      if (qWords.isEmpty) continue;

      FoodItem? best;
      var bestRank = 999;

      for (final food in catalogue) {
        final nameLower = food.name.toLowerCase();
        final aliasesLower = [for (final a in food.aliases) a.toLowerCase()];
        if (nameLower == q || aliasesLower.contains(q)) {
          return food;
        }
        final allTextWords = <String>{
          ..._words(nameLower),
          for (final a in aliasesLower) ..._words(a),
        };
        if (qWords.every(allTextWords.contains)) {
          final rank = nameLower.startsWith(q)
              ? 1
              : aliasesLower.any((a) => a.startsWith(q))
              ? 2
              : 3 + food.name.length;
          if (rank < bestRank) {
            bestRank = rank;
            best = food;
          }
        }
      }
      if (best != null) return best;
    }
    return null;
  }

  static (String, double) _resolvePortion(FoodItem food, RawAiMealItem item) {
    final u = item.unit.toLowerCase();
    final qty = item.quantity > 0 ? item.quantity : 1.0;

    if (u == 'g' || u == 'gram' || u == 'grams' || u == 'ml') {
      final grams = qty > 5 ? qty : item.estimatedGrams;
      return ('g', grams.clamp(1.0, 5000.0));
    }

    for (final p in food.portions) {
      final pu = p.unit.toLowerCase();
      if (pu == u || pu.contains(u) || u.contains(pu)) {
        if (pu != 'g') return (p.unit, qty);
      }
    }

    // Synonym mapping for household Indian units.
    const synonyms = <String, List<String>>{
      'bowl': ['katori', 'bowl'],
      'katori': ['katori', 'bowl'],
      'piece': ['piece', '1 egg', 'fillet', 'slice'],
      'roti': ['piece'],
      'egg': ['1 egg', 'piece'],
      'cup': ['cup', 'glass', 'katori'],
      'glass': ['glass', 'cup'],
    };
    final candidates = synonyms[u] ?? const [];
    for (final candidate in candidates) {
      for (final p in food.portions) {
        if (p.unit.toLowerCase().contains(candidate) && p.unit != 'g') {
          return (p.unit, qty);
        }
      }
    }

    if (item.estimatedGrams > 0) {
      return ('g', item.estimatedGrams.clamp(1.0, 5000.0));
    }
    final firstNamed = food.portions.first;
    return (firstNamed.unit, qty);
  }

  static List<String> _words(String text) => text
      .split(RegExp(r'[^a-z0-9]+'))
      .where((w) => w.length >= 2 && !_stopWords.contains(w))
      .toList();

  static const _stopWords = {
    'with',
    'without',
    'and',
    'aur',
    'ke',
    'ka',
    'ki',
    'saath',
    'no',
    'home',
    'style',
  };
}
