import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/db/converters.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/rounding.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Strips any clock time so diary queries always key by calendar date.
DateTime diaryDay(DateTime date) => DateTime(date.year, date.month, date.day);

/// Reversible handle returned by every one-tap or destructive action (PRD N11).
@immutable
class UndoAction {
  const UndoAction({required this.message, required this.undo});

  final String message;
  final Future<void> Function() undo;
}

/// Input to log a single dish onto a diary day.
@immutable
class NewMealEntry {
  const NewMealEntry({
    this.foodId,
    required this.name,
    required this.meal,
    required this.day,
    this.portionUnit,
    this.portionCount,
    this.oilLevel,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.source,
    this.eatenAt,
  });

  final String? foodId;
  final String name;
  final Meal meal;
  final DateTime day;
  final String? portionUnit;
  final double? portionCount;
  final OilLevel? oilLevel;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final EntrySource source;
  final DateTime? eatenAt;
}

/// One dish inside a saved meal template (PRD N3).
@immutable
class SavedMealDraftItem {
  const SavedMealDraftItem({
    this.foodId,
    required this.name,
    this.portionUnit,
    this.portionCount,
    this.oilLevel,
    required this.grams,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String? foodId;
  final String name;
  final String? portionUnit;
  final double? portionCount;
  final OilLevel? oilLevel;
  final double grams;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
}

/// A saved meal with its ordered dishes.
@immutable
class SavedMealBundle {
  const SavedMealBundle({required this.meal, required this.items});

  final SavedMealRow meal;
  final List<SavedMealItemRow> items;

  double get totalKcal => items.fold<double>(0, (sum, item) => sum + item.kcal);

  double get totalProteinG =>
      items.fold<double>(0, (sum, item) => sum + item.proteinG);
}

/// Everything logged on a single diary [day] (PRD D1).
@immutable
class DaySummary {
  const DaySummary({
    required this.day,
    required this.entries,
    required this.waterSamples,
    required this.stepsSamples,
    required this.weightLog,
  });

  final DateTime day;
  final List<MealEntryRow> entries;
  final List<HealthSampleRow> waterSamples;
  final List<HealthSampleRow> stepsSamples;
  final WeightLogRow? weightLog;

  double get totalKcal => entries.fold<double>(0, (sum, e) => sum + e.kcal);
  double get totalProteinG =>
      entries.fold<double>(0, (sum, e) => sum + e.proteinG);
  double get totalCarbsG => entries.fold<double>(0, (sum, e) => sum + e.carbsG);
  double get totalFatG => entries.fold<double>(0, (sum, e) => sum + e.fatG);

  int get waterMl =>
      waterSamples.fold<double>(0, (sum, s) => sum + s.value).round();

  int get steps =>
      stepsSamples.fold<double>(0, (sum, s) => sum + s.value).round();

  List<MealEntryRow> entriesFor(Meal meal) => [
    for (final entry in entries)
      if (entry.meal == meal) entry,
  ];
}

/// Rolling 7-day average worked out directly from logs, never stored (PRD D2).
@immutable
class SevenDayAverage {
  const SevenDayAverage({
    required this.avgKcal,
    required this.avgProteinG,
    required this.daysLogged,
  });

  final double avgKcal;
  final double avgProteinG;
  final int daysLogged;
}

/// Phone-first diary operations for meals, saved meals, water, steps and
/// weigh-ins. Every write updates Drift immediately with `dirty = true`, and
/// deletes set `deletedAt` so sync propagates them across phones.
class LogRepository {
  LogRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Live summary of [day]'s meals, water, steps and weigh-in.
  Stream<DaySummary> watchDay(DateTime day) {
    final d = diaryDay(day);
    return _db
        .customSelect(
          'SELECT 1',
          readsFrom: {_db.mealEntries, _db.healthSamples, _db.weightLogs},
        )
        .watch()
        .asyncMap((_) => getDay(d));
  }

  /// Snapshot of [day]'s meals, water, steps and weigh-in.
  Future<DaySummary> getDay(DateTime day) async {
    final d = diaryDay(day);
    final entries =
        await (_db.select(_db.mealEntries)
              ..where((e) => e.day.equalsValue(d) & e.deletedAt.isNull())
              ..orderBy([
                (e) => OrderingTerm.asc(e.eatenAt),
                (e) => OrderingTerm.asc(e.createdAt),
              ]))
            .get();
    final samples =
        await (_db.select(_db.healthSamples)
              ..where((s) => s.day.equalsValue(d) & s.deletedAt.isNull())
              ..orderBy([(s) => OrderingTerm.asc(s.measuredAt)]))
            .get();
    final weight =
        await (_db.select(_db.weightLogs)
              ..where((w) => w.day.equalsValue(d) & w.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();

    final water = <HealthSampleRow>[];
    final steps = <HealthSampleRow>[];
    for (final sample in samples) {
      if (sample.metric == HealthMetric.waterMl) {
        water.add(sample);
      } else if (sample.metric == HealthMetric.steps) {
        steps.add(sample);
      }
    }
    return DaySummary(
      day: d,
      entries: entries,
      waterSamples: water,
      stepsSamples: steps,
      weightLog: weight,
    );
  }

  /// Live 7-day rolling average ending on [endDay] inclusive (PRD D2).
  /// Averages across days in the 7-day window that have at least one meal log.
  Stream<SevenDayAverage> watchSevenDayAverage(DateTime endDay) {
    final end = diaryDay(endDay);
    final start = DateTime(end.year, end.month, end.day - 6);
    const conv = DateConverter();
    final startSql = conv.toSql(start);
    final endSql = conv.toSql(end);

    return (_db.select(_db.mealEntries)..where(
          (e) =>
              e.deletedAt.isNull() &
              e.day.isBiggerOrEqualValue(startSql) &
              e.day.isSmallerOrEqualValue(endSql),
        ))
        .watch()
        .map((rows) {
          if (rows.isEmpty) {
            return const SevenDayAverage(
              avgKcal: 0,
              avgProteinG: 0,
              daysLogged: 0,
            );
          }
          final byDay = <String, (double, double)>{};
          for (final row in rows) {
            final key = conv.toSql(row.day);
            final prev = byDay[key] ?? (0.0, 0.0);
            byDay[key] = (prev.$1 + row.kcal, prev.$2 + row.proteinG);
          }
          final count = byDay.length;
          var sumKcal = 0.0;
          var sumProtein = 0.0;
          for (final totals in byDay.values) {
            sumKcal += totals.$1;
            sumProtein += totals.$2;
          }
          return SevenDayAverage(
            avgKcal: roundHalfEven(sumKcal / count, 0),
            avgProteinG: roundHalfEven(sumProtein / count, 0),
            daysLogged: count,
          );
        });
  }

  /// Every diary day with a meal logged on it, for Josh's streak and the
  /// Progress calendar. A day leaves only if every meal on it is deleted.
  Stream<Set<DateTime>> watchLoggedDays() {
    final day = _db.mealEntries.day;
    final query = _db.selectOnly(_db.mealEntries, distinct: true)
      ..addColumns([day])
      ..where(_db.mealEntries.deletedAt.isNull());
    return query.watch().map(
      (rows) => {for (final row in rows) row.readWithConverter(day)!},
    );
  }

  /// Weigh-ins on or after [from], oldest first, for the weight trend
  /// (PRD D3).
  Stream<List<WeightLogRow>> watchWeighIns({required DateTime from}) {
    final fromSql = const DateConverter().toSql(diaryDay(from));
    return (_db.select(_db.weightLogs)
          ..where(
            (w) => w.deletedAt.isNull() & w.day.isBiggerOrEqualValue(fromSql),
          )
          ..orderBy([(w) => OrderingTerm.asc(w.day)]))
        .watch();
  }

  /// Yesterday's live entries for [meal] relative to [viewedDay].
  Future<List<MealEntryRow>> yesterdayEntriesFor(
    DateTime viewedDay,
    Meal meal,
  ) {
    final prev = DateTime(viewedDay.year, viewedDay.month, viewedDay.day - 1);
    return (_db.select(_db.mealEntries)
          ..where(
            (e) =>
                e.day.equalsValue(prev) &
                e.meal.equalsValue(meal) &
                e.deletedAt.isNull(),
          )
          ..orderBy([(e) => OrderingTerm.asc(e.eatenAt)]))
        .get();
  }

  /// Recent distinct dishes logged by the user, for 1-tap re-logging within
  /// thumb reach (PRD Experience rules).
  Stream<List<MealEntryRow>> watchRecentFoods({int limit = 8}) =>
      (_db.select(_db.mealEntries)
            ..where((e) => e.deletedAt.isNull())
            ..orderBy([(e) => OrderingTerm.desc(e.eatenAt)])
            ..limit(60))
          .watch()
          .map((rows) {
            final seen = <String>{};
            final distinct = <MealEntryRow>[];
            for (final row in rows) {
              final key =
                  '${row.foodId ?? row.name.toLowerCase()}|'
                  '${row.portionUnit}|${row.portionCount}|${row.oilLevel?.storage}';
              if (seen.add(key)) {
                distinct.add(row);
                if (distinct.length >= limit) break;
              }
            }
            return distinct;
          });

  /// Live list of saved meals / favourites with their items (PRD N3).
  Stream<List<SavedMealBundle>> watchSavedMeals() => _db
      .customSelect('SELECT 1', readsFrom: {_db.savedMeals, _db.savedMealItems})
      .watch()
      .asyncMap((_) => getSavedMeals());

  Future<List<SavedMealBundle>> getSavedMeals() async {
    final meals =
        await (_db.select(_db.savedMeals)
              ..where((m) => m.deletedAt.isNull())
              ..orderBy([(m) => OrderingTerm.desc(m.updatedAt)]))
            .get();
    if (meals.isEmpty) return const <SavedMealBundle>[];
    final ids = [for (final m in meals) m.id];
    final items =
        await (_db.select(_db.savedMealItems)
              ..where((i) => i.savedMealId.isIn(ids) & i.deletedAt.isNull())
              ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
            .get();
    final byMeal = <String, List<SavedMealItemRow>>{};
    for (final item in items) {
      (byMeal[item.savedMealId] ??= []).add(item);
    }
    return [
      for (final meal in meals)
        if ((byMeal[meal.id] ?? const []).isNotEmpty)
          SavedMealBundle(meal: meal, items: byMeal[meal.id]!),
    ];
  }

  /// Logs one dish and returns an [UndoAction] that soft-deletes it.
  Future<UndoAction> logEntry(NewMealEntry input) =>
      logEntries([input], summaryLabel: 'Logged ${input.name}');

  /// Logs one or more dishes in a single transaction, returning an [UndoAction]
  /// that soft-deletes the whole batch.
  Future<UndoAction> logEntries(
    List<NewMealEntry> inputs, {
    required String summaryLabel,
  }) async {
    if (inputs.isEmpty) {
      return UndoAction(message: summaryLabel, undo: () async {});
    }
    final now = clock.now();
    final ids = <String>[];
    await _db.transaction(() async {
      for (final input in inputs) {
        final id = _uuid.v7();
        ids.add(id);
        await _db
            .into(_db.mealEntries)
            .insert(
              MealEntriesCompanion.insert(
                id: id,
                foodId: Value(input.foodId),
                name: _trimMax(input.name, 200),
                meal: input.meal,
                day: diaryDay(input.day),
                portionUnit: Value(input.portionUnit),
                portionCount: Value(
                  input.portionCount == null
                      ? null
                      : _clampRound(input.portionCount!, 0.1, 5000, 2),
                ),
                oilLevel: Value(input.oilLevel),
                grams: _clampRound(input.grams, 0.1, 5000, 1),
                kcal: _clampRound(input.kcal, 0, 10000, 1),
                proteinG: _clampRound(input.proteinG, 0, 1000, 1),
                carbsG: _clampRound(input.carbsG, 0, 2000, 1),
                fatG: _clampRound(input.fatG, 0, 1000, 1),
                eatenAt: input.eatenAt ?? now,
                source: input.source,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
    return UndoAction(
      message: summaryLabel,
      undo: () => _softDeleteMealIds(ids),
    );
  }

  /// Edits an existing meal entry in place (PRD N11).
  Future<void> updateMealEntry({
    required String id,
    required Meal meal,
    String? portionUnit,
    double? portionCount,
    OilLevel? oilLevel,
    required double grams,
    required double kcal,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    final now = clock.now();
    await (_db.update(_db.mealEntries)..where((e) => e.id.equals(id))).write(
      MealEntriesCompanion(
        meal: Value(meal),
        portionUnit: Value(portionUnit),
        portionCount: Value(
          portionCount == null ? null : _clampRound(portionCount, 0.1, 5000, 2),
        ),
        oilLevel: Value(oilLevel),
        grams: Value(_clampRound(grams, 0.1, 5000, 1)),
        kcal: Value(_clampRound(kcal, 0, 10000, 1)),
        proteinG: Value(_clampRound(proteinG, 0, 1000, 1)),
        carbsG: Value(_clampRound(carbsG, 0, 2000, 1)),
        fatG: Value(_clampRound(fatG, 0, 1000, 1)),
        updatedAt: Value(now),
        dirty: const Value(true),
      ),
    );
  }

  /// Soft-deletes a meal entry and returns an [UndoAction] to restore it.
  Future<UndoAction> deleteMealEntry(MealEntryRow entry) async {
    await _softDeleteMealIds([entry.id]);
    return UndoAction(
      message: 'Removed ${entry.name}',
      undo: () async {
        final now = clock.now();
        await (_db.update(
          _db.mealEntries,
        )..where((e) => e.id.equals(entry.id))).write(
          MealEntriesCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now),
            dirty: const Value(true),
          ),
        );
      },
    );
  }

  /// Repeats yesterday's entries for [meal] onto [day] in one tap (PRD N3).
  Future<UndoAction?> repeatYesterdayMeal({
    required DateTime day,
    required Meal meal,
  }) async {
    final previous = await yesterdayEntriesFor(day, meal);
    if (previous.isEmpty) return null;
    final inputs = [
      for (final item in previous)
        NewMealEntry(
          foodId: item.foodId,
          name: item.name,
          meal: meal,
          day: day,
          portionUnit: item.portionUnit,
          portionCount: item.portionCount,
          oilLevel: item.oilLevel,
          grams: item.grams,
          kcal: item.kcal,
          proteinG: item.proteinG,
          carbsG: item.carbsG,
          fatG: item.fatG,
          source: EntrySource.repeat,
        ),
    ];
    return logEntries(
      inputs,
      summaryLabel: 'Repeated yesterday\'s ${meal.label.toLowerCase()}',
    );
  }

  /// Saves a favourite dish or whole meal combo to `saved_meals` (PRD N3).
  Future<SavedMealRow> saveMealTemplate({
    required String name,
    required List<SavedMealDraftItem> items,
  }) => _db.transaction(() async {
    final now = clock.now();
    final mealId = _uuid.v7();
    await _db
        .into(_db.savedMeals)
        .insert(
          SavedMealsCompanion.insert(
            id: mealId,
            name: _trimMax(name.trim(), 120),
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      await _db
          .into(_db.savedMealItems)
          .insert(
            SavedMealItemsCompanion.insert(
              id: _uuid.v7(),
              savedMealId: mealId,
              foodId: Value(item.foodId),
              name: _trimMax(item.name, 200),
              portionUnit: Value(item.portionUnit),
              portionCount: Value(
                item.portionCount == null
                    ? null
                    : _clampRound(item.portionCount!, 0.1, 5000, 2),
              ),
              oilLevel: Value(item.oilLevel),
              grams: _clampRound(item.grams, 0.1, 5000, 1),
              kcal: _clampRound(item.kcal, 0, 10000, 1),
              proteinG: _clampRound(item.proteinG, 0, 1000, 1),
              carbsG: _clampRound(item.carbsG, 0, 2000, 1),
              fatG: _clampRound(item.fatG, 0, 1000, 1),
              sortOrder: Value(i),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    return (_db.select(
      _db.savedMeals,
    )..where((m) => m.id.equals(mealId))).getSingle();
  });

  /// Logs every dish in [bundle] onto [day] & [meal] in one tap (PRD N3).
  Future<UndoAction> logSavedMeal({
    required SavedMealBundle bundle,
    required DateTime day,
    required Meal meal,
  }) => logEntries([
    for (final item in bundle.items)
      NewMealEntry(
        foodId: item.foodId,
        name: item.name,
        meal: meal,
        day: day,
        portionUnit: item.portionUnit,
        portionCount: item.portionCount,
        oilLevel: item.oilLevel,
        grams: item.grams,
        kcal: item.kcal,
        proteinG: item.proteinG,
        carbsG: item.carbsG,
        fatG: item.fatG,
        source: EntrySource.repeat,
      ),
  ], summaryLabel: 'Logged ${bundle.meal.name}');

  /// Soft-deletes a saved meal and its items, with Undo.
  Future<UndoAction> deleteSavedMeal(SavedMealBundle bundle) async {
    final now = clock.now();
    await _db.transaction(() async {
      await (_db.update(
        _db.savedMeals,
      )..where((m) => m.id.equals(bundle.meal.id))).write(
        SavedMealsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          dirty: const Value(true),
        ),
      );
      await (_db.update(
        _db.savedMealItems,
      )..where((i) => i.savedMealId.equals(bundle.meal.id))).write(
        SavedMealItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          dirty: const Value(true),
        ),
      );
    });
    return UndoAction(
      message: 'Removed ${bundle.meal.name}',
      undo: () async {
        final restoreAt = clock.now();
        await _db.transaction(() async {
          await (_db.update(
            _db.savedMeals,
          )..where((m) => m.id.equals(bundle.meal.id))).write(
            SavedMealsCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(restoreAt),
              dirty: const Value(true),
            ),
          );
          for (final item in bundle.items) {
            await (_db.update(
              _db.savedMealItems,
            )..where((i) => i.id.equals(item.id))).write(
              SavedMealItemsCompanion(
                deletedAt: const Value(null),
                updatedAt: Value(restoreAt),
                dirty: const Value(true),
              ),
            );
          }
        });
      },
    );
  }

  /// Adds [ml] of water (default 250 ml, 1 glass) on [day] with 1-tap Undo
  /// (PRD N5, N11).
  Future<UndoAction> addWater({required DateTime day, int ml = 250}) async {
    final now = clock.now();
    final id = _uuid.v7();
    final safeMl = _clampRound(ml.toDouble(), 1, 5000, 0);
    await _db
        .into(_db.healthSamples)
        .insert(
          HealthSamplesCompanion.insert(
            id: id,
            metric: HealthMetric.waterMl,
            day: diaryDay(day),
            value: safeMl,
            measuredAt: now,
            source: SampleSource.manual,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return UndoAction(
      message: 'Added ${safeMl.round()} ml water',
      undo: () => _softDeleteHealthSample(id),
    );
  }

  /// Updates the amount of a water or steps reading (PRD N11).
  Future<void> updateHealthSample({
    required HealthSampleRow sample,
    required double value,
  }) async {
    final maxVal = sample.metric == HealthMetric.waterMl ? 5000.0 : 100000.0;
    final now = clock.now();
    await (_db.update(
      _db.healthSamples,
    )..where((s) => s.id.equals(sample.id))).write(
      HealthSamplesCompanion(
        value: Value(_clampRound(value, 0, maxVal, 0)),
        updatedAt: Value(now),
        dirty: const Value(true),
      ),
    );
  }

  /// Soft-deletes a water or steps reading with Undo (PRD N11).
  Future<UndoAction> deleteHealthSample(HealthSampleRow sample) async {
    await _softDeleteHealthSample(sample.id);
    final label = sample.metric == HealthMetric.waterMl
        ? '${sample.value.round()} ml water'
        : '${sample.value.round()} steps';
    return UndoAction(
      message: 'Removed $label',
      undo: () async {
        final now = clock.now();
        await (_db.update(
          _db.healthSamples,
        )..where((s) => s.id.equals(sample.id))).write(
          HealthSamplesCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now),
            dirty: const Value(true),
          ),
        );
      },
    );
  }

  /// Sets [steps] walked on [day] (entered by hand at launch, PRD N5).
  Future<UndoAction> setStepsForDay({
    required DateTime day,
    required int steps,
  }) async {
    final d = diaryDay(day);
    final now = clock.now();
    final safeSteps = _clampRound(steps.toDouble(), 0, 100000, 0);
    final existing =
        await (_db.select(_db.healthSamples)..where(
              (s) =>
                  s.day.equalsValue(d) &
                  s.metric.equalsValue(HealthMetric.steps) &
                  s.deletedAt.isNull(),
            ))
            .get();

    if (existing.isEmpty) {
      final id = _uuid.v7();
      await _db
          .into(_db.healthSamples)
          .insert(
            HealthSamplesCompanion.insert(
              id: id,
              metric: HealthMetric.steps,
              day: d,
              value: safeSteps,
              measuredAt: now,
              source: SampleSource.manual,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return UndoAction(
        message: 'Saved ${safeSteps.round()} steps',
        undo: () => _softDeleteHealthSample(id),
      );
    }

    final first = existing.first;
    final previousValue = first.value;
    await _db.transaction(() async {
      await (_db.update(
        _db.healthSamples,
      )..where((s) => s.id.equals(first.id))).write(
        HealthSamplesCompanion(
          value: Value(safeSteps),
          updatedAt: Value(now),
          dirty: const Value(true),
        ),
      );
      for (final extra in existing.skip(1)) {
        await _softDeleteHealthSample(extra.id);
      }
    });
    return UndoAction(
      message: 'Updated steps to ${safeSteps.round()}',
      undo: () async {
        final restoreAt = clock.now();
        await (_db.update(
          _db.healthSamples,
        )..where((s) => s.id.equals(first.id))).write(
          HealthSamplesCompanion(
            value: Value(previousValue),
            updatedAt: Value(restoreAt),
            dirty: const Value(true),
          ),
        );
      },
    );
  }

  /// Logs or updates the weigh-in for [day] with Undo (PRD N11).
  Future<UndoAction> saveWeightForDay({
    required DateTime day,
    required double weightKg,
  }) async {
    final d = diaryDay(day);
    final now = clock.now();
    final rounded = _clampRound(weightKg, 20, 400, 1);
    final existing =
        await (_db.select(_db.weightLogs)
              ..where((w) => w.day.equalsValue(d) & w.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();

    if (existing == null) {
      final id = _uuid.v7();
      await _db
          .into(_db.weightLogs)
          .insert(
            WeightLogsCompanion.insert(
              id: id,
              day: d,
              weightKg: rounded,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return UndoAction(
        message: 'Logged $rounded kg',
        undo: () async {
          final delAt = clock.now();
          await (_db.update(
            _db.weightLogs,
          )..where((w) => w.id.equals(id))).write(
            WeightLogsCompanion(
              deletedAt: Value(delAt),
              updatedAt: Value(delAt),
              dirty: const Value(true),
            ),
          );
        },
      );
    }

    final prev = existing.weightKg;
    await (_db.update(
      _db.weightLogs,
    )..where((w) => w.id.equals(existing.id))).write(
      WeightLogsCompanion(
        weightKg: Value(rounded),
        updatedAt: Value(now),
        dirty: const Value(true),
      ),
    );
    return UndoAction(
      message: 'Updated weight to $rounded kg',
      undo: () async {
        final restoreAt = clock.now();
        await (_db.update(
          _db.weightLogs,
        )..where((w) => w.id.equals(existing.id))).write(
          WeightLogsCompanion(
            weightKg: Value(prev),
            updatedAt: Value(restoreAt),
            dirty: const Value(true),
          ),
        );
      },
    );
  }

  /// Soft-deletes a weigh-in with Undo (PRD N11).
  Future<UndoAction> deleteWeightLog(WeightLogRow row) async {
    final now = clock.now();
    await (_db.update(_db.weightLogs)..where((w) => w.id.equals(row.id))).write(
      WeightLogsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        dirty: const Value(true),
      ),
    );
    return UndoAction(
      message: 'Removed weigh-in',
      undo: () async {
        final restoreAt = clock.now();
        await (_db.update(
          _db.weightLogs,
        )..where((w) => w.id.equals(row.id))).write(
          WeightLogsCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(restoreAt),
            dirty: const Value(true),
          ),
        );
      },
    );
  }

  Future<void> _softDeleteMealIds(List<String> ids) async {
    if (ids.isEmpty) return;
    final now = clock.now();
    await (_db.update(_db.mealEntries)..where((e) => e.id.isIn(ids))).write(
      MealEntriesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        dirty: const Value(true),
      ),
    );
  }

  Future<void> _softDeleteHealthSample(String id) async {
    final now = clock.now();
    await (_db.update(_db.healthSamples)..where((s) => s.id.equals(id))).write(
      HealthSamplesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        dirty: const Value(true),
      ),
    );
  }
}

String _trimMax(String s, int maxLen) {
  final t = s.trim();
  if (t.isEmpty) return 'Item';
  return t.length <= maxLen ? t : t.substring(0, maxLen);
}

double _clampRound(double v, double min, double max, int places) {
  final clamped = v < min ? min : (v > max ? max : v);
  return roundHalfEven(clamped, places);
}
