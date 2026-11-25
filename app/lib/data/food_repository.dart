import 'dart:convert';
import 'dart:io';

import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/sync/sync_remote.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/oil.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// One named portion of a food, such as 1 katori = 150 g or 1 piece = 30 g.
@immutable
class FoodPortion {
  const FoodPortion({required this.unit, required this.grams});

  final String unit;
  final double grams;

  factory FoodPortion.fromJson(Map<String, Object?> json) => FoodPortion(
    unit: json['unit']! as String,
    grams: (json['grams']! as num).toDouble(),
  );
}

/// A verified food from the catalogue, decoded for fast search and portion
/// selection.
@immutable
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.aliases,
    required this.kcalPer100g,
    required this.proteinGPer100g,
    required this.carbsGPer100g,
    required this.fatGPer100g,
    required this.portions,
    required this.assumption,
    required this.source,
  });

  final String id;
  final String name;
  final List<String> aliases;
  final double kcalPer100g;
  final double proteinGPer100g;
  final double carbsGPer100g;
  final double fatGPer100g;
  final List<FoodPortion> portions;
  final String assumption;
  final String source;

  factory FoodItem.fromRow(FoodRow row) {
    final rawAliases = (jsonDecode(row.aliasesJson) as List<Object?>)
        .cast<String>();
    final rawPortions = (jsonDecode(row.portionsJson) as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(FoodPortion.fromJson)
        .toList();
    return FoodItem(
      id: row.id,
      name: row.name,
      aliases: rawAliases,
      kcalPer100g: row.kcalPer100g,
      proteinGPer100g: row.proteinGPer100g,
      carbsGPer100g: row.carbsGPer100g,
      fatGPer100g: row.fatGPer100g,
      portions: [
        ...rawPortions,
        if (!rawPortions.any((p) => p.unit == 'g'))
          const FoodPortion(unit: 'g', grams: 1),
      ],
      assumption: row.assumption,
      source: row.source,
    );
  }

  OilLevel get defaultOil =>
      defaultOilLevel(assumption: assumption, source: source);

  CalculatedNutrients calculate({
    required String unit,
    required double count,
    required OilLevel? oilLevel,
  }) {
    final portion = portions.firstWhere(
      (p) => p.unit == unit,
      orElse: () => const FoodPortion(unit: 'g', grams: 1),
    );
    return calculateFoodNutrients(
      kcalPer100g: kcalPer100g,
      proteinGPer100g: proteinGPer100g,
      carbsGPer100g: carbsGPer100g,
      fatGPer100g: fatGPer100g,
      assumption: assumption,
      source: source,
      grams: portion.grams * count,
      oilLevel: oilLevel,
    );
  }
}

/// Offline-first food catalogue: seeded from `assets/foods.json` on first use
/// and updated incrementally from Supabase by `seq` (PRD N1, Food data).
class FoodRepository {
  FoodRepository(this._db, {Future<String> Function()? loadSeedJson})
    : _loadSeedJson = loadSeedJson ?? _defaultLoadSeedJson;

  static Future<String> _defaultLoadSeedJson() {
    final localAsset = File('assets/foods.json');
    if (localAsset.existsSync()) {
      return Future.value(localAsset.readAsStringSync());
    }
    return rootBundle.loadString('assets/foods.json');
  }

  final AppDatabase _db;
  final Future<String> Function() _loadSeedJson;
  List<FoodItem>? _bundledCache;
  int _maxBundledSeq = 0;
  List<FoodItem>? _cache;
  Future<void>? _seeding;

  Future<List<FoodItem>> _loadBundled() async {
    if (_bundledCache case final cached?) return cached;
    final raw = await _loadSeedJson();
    final items = (jsonDecode(raw) as List<Object?>)
        .cast<Map<String, Object?>>();
    var maxSeq = 0;
    final parsed = <FoodItem>[];
    for (final item in items) {
      final seq = (item['seq']! as num).toInt();
      if (seq > maxSeq) maxSeq = seq;
      final rawPortions = ((item['portions'] as List<Object?>?) ?? const [])
          .cast<Map<String, Object?>>()
          .map(FoodPortion.fromJson)
          .toList();
      parsed.add(
        FoodItem(
          id: item['id']! as String,
          name: item['name']! as String,
          aliases: ((item['aliases'] as List<Object?>?) ?? const [])
              .cast<String>(),
          kcalPer100g: (item['kcal_per_100g']! as num).toDouble(),
          proteinGPer100g: (item['protein_g_per_100g']! as num).toDouble(),
          carbsGPer100g: (item['carbs_g_per_100g']! as num).toDouble(),
          fatGPer100g: (item['fat_g_per_100g']! as num).toDouble(),
          portions: [
            ...rawPortions,
            if (!rawPortions.any((p) => p.unit == 'g'))
              const FoodPortion(unit: 'g', grams: 1),
          ],
          assumption: (item['assumption'] as String?) ?? '',
          source: item['source']! as String,
        ),
      );
    }
    _maxBundledSeq = maxSeq;
    return _bundledCache = parsed;
  }

  /// Writes the bundled catalogue into SQLite (used by catalogue integrity
  /// tests and before syncing deltas if needed).
  Future<void> ensureSeeded() => _seeding ??= _seedIfNeeded();

  Future<void> _seedIfNeeded() async {
    final existing = await (_db.select(_db.foods)..limit(1)).getSingleOrNull();
    if (existing != null) return;

    final raw = await _loadSeedJson();
    final items = (jsonDecode(raw) as List<Object?>)
        .cast<Map<String, Object?>>();
    var maxSeq = 0;
    await _db.transaction(() async {
      await _db.batch((batch) {
        for (final item in items) {
          final seq = (item['seq']! as num).toInt();
          if (seq > maxSeq) maxSeq = seq;
          batch.insert(
            _db.foods,
            FoodsCompanion.insert(
              id: item['id']! as String,
              name: item['name']! as String,
              aliasesJson: Value(jsonEncode(item['aliases'] ?? const [])),
              kcalPer100g: (item['kcal_per_100g']! as num).toDouble(),
              proteinGPer100g: (item['protein_g_per_100g']! as num).toDouble(),
              carbsGPer100g: (item['carbs_g_per_100g']! as num).toDouble(),
              fatGPer100g: (item['fat_g_per_100g']! as num).toDouble(),
              portionsJson: Value(jsonEncode(item['portions'] ?? const [])),
              assumption: Value((item['assumption'] as String?) ?? ''),
              source: item['source']! as String,
              seq: Value(seq),
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
      final cursor = await (_db.select(
        _db.syncCursors,
      )..where((c) => c.kind.equals('foods'))).getSingleOrNull();
      if (cursor == null && maxSeq > 0) {
        await _db
            .into(_db.syncCursors)
            .insert(SyncCursorsCompanion.insert(kind: 'foods', seq: maxSeq));
      }
    });
    _cache = null;
  }

  /// All active foods in memory for sub-10ms search across names and Hindi /
  /// Hinglish aliases. Merges bundled foods with any synced server deltas.
  Future<List<FoodItem>> allFoods() async {
    if (_cache case final cached?) return cached;
    final bundled = await _loadBundled();
    final dbRows = await _db.select(_db.foods).get();
    final byId = <String, FoodItem>{for (final f in bundled) f.id: f};
    for (final row in dbRows) {
      if (row.deletedAt != null) {
        byId.remove(row.id);
      } else {
        byId[row.id] = FoodItem.fromRow(row);
      }
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return _cache = List.unmodifiable(merged);
  }

  Future<FoodItem?> byId(String id) async {
    final all = await allFoods();
    for (final food in all) {
      if (food.id == id) return food;
    }
    return null;
  }

  /// Searches names and Hindi / Hinglish aliases in memory (< 10 ms for 500+
  /// dishes). Exact and prefix matches rank ahead of word and substring hits.
  Future<List<FoodItem>> search(String query, {int limit = 30}) async {
    final all = await allFoods();
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return all.take(limit).toList();

    final tokens = trimmed
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final scored = <(int, FoodItem)>[];
    for (final food in all) {
      final score = _scoreFood(food, trimmed, tokens);
      if (score != null) scored.add((score, food));
    }
    scored.sort((a, b) {
      final byScore = a.$1.compareTo(b.$1);
      return byScore != 0 ? byScore : a.$2.name.compareTo(b.$2.name);
    });
    return [for (final entry in scored.take(limit)) entry.$2];
  }

  /// Pulls any catalogue additions or edits after the phone's `foods` cursor.
  Future<void> syncCatalogue(SyncRemote remote) async {
    await _loadBundled();
    var after =
        (await (_db.select(
          _db.syncCursors,
        )..where((c) => c.kind.equals('foods'))).getSingleOrNull())?.seq ??
        _maxBundledSeq;
    const batchSize = 500;
    for (var round = 0; round < 50; round++) {
      final rows = await remote.pull('foods', after: after, limit: batchSize);
      if (rows.isEmpty) break;
      await _db.transaction(() async {
        for (final row in rows) {
          final seq = (row['seq']! as num).toInt();
          if (seq > after) after = seq;
          final deletedText = row['deleted_at'] as String?;
          await _db
              .into(_db.foods)
              .insertOnConflictUpdate(
                FoodsCompanion.insert(
                  id: row['id']! as String,
                  name: row['name']! as String,
                  aliasesJson: Value(jsonEncode(row['aliases'] ?? const [])),
                  kcalPer100g: (row['kcal_per_100g']! as num).toDouble(),
                  proteinGPer100g: (row['protein_g_per_100g']! as num)
                      .toDouble(),
                  carbsGPer100g: (row['carbs_g_per_100g']! as num).toDouble(),
                  fatGPer100g: (row['fat_g_per_100g']! as num).toDouble(),
                  portionsJson: Value(jsonEncode(row['portions'] ?? const [])),
                  assumption: Value((row['assumption'] as String?) ?? ''),
                  source: row['source']! as String,
                  deletedAt: Value(
                    deletedText == null ? null : DateTime.parse(deletedText),
                  ),
                  seq: Value(seq),
                ),
              );
        }
        await _db
            .into(_db.syncCursors)
            .insertOnConflictUpdate(
              SyncCursorsCompanion.insert(kind: 'foods', seq: after),
            );
      });
      _cache = null;
      if (rows.length < batchSize) break;
    }
  }

  static int? _scoreFood(FoodItem food, String fullQuery, List<String> tokens) {
    final name = food.name.toLowerCase();
    final aliases = [for (final a in food.aliases) a.toLowerCase()];
    final haystack = [name, ...aliases].join(' ');

    for (final token in tokens) {
      if (!haystack.contains(token)) return null;
    }
    if (name == fullQuery || aliases.contains(fullQuery)) return 0;
    if (name.startsWith(fullQuery)) return 1;
    if (aliases.any((a) => a.startsWith(fullQuery))) return 2;
    if (name.split(RegExp(r'[\s()/,-]+')).any((w) => w.startsWith(fullQuery))) {
      return 3;
    }
    if (aliases.any(
      (a) => a.split(RegExp(r'[\s()/,-]+')).any((w) => w.startsWith(fullQuery)),
    )) {
      return 4;
    }
    return 5;
  }
}
