import 'dart:convert';

import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/db/converters.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/models/options.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One exported file ready for the phone's share sheet.
@immutable
class ExportedFile {
  const ExportedFile({required this.name, required this.content});

  final String name;
  final String content;
}

/// Sends exported files through the phone's own share sheet.
abstract interface class ShareService {
  Future<void> shareFiles(List<ExportedFile> files);
}

class MethodChannelShareService implements ShareService {
  const MethodChannelShareService();

  static const _channel = MethodChannel('com.naman9245.aurafit/share');

  @override
  Future<void> shareFiles(List<ExportedFile> files) async {
    await _channel.invokeMethod<bool>('shareFiles', {
      'files': [
        for (final file in files) {'name': file.name, 'content': file.content},
      ],
    });
  }
}

final shareServiceProvider = Provider<ShareService>(
  (ref) => const MethodChannelShareService(),
);

/// Builds the person's full data export (JSON and CSV) on the phone from its
/// own database, offline, in seconds (PRD A6).
class DataExporter {
  const DataExporter(this._db);

  final AppDatabase _db;
  static const _dates = DateConverter();

  Future<List<ExportedFile>> buildExport() => _db.transaction(() async {
    final exportedAt = clock.now().toUtc().toIso8601String();
    final profile = await (_db.select(
      _db.profiles,
    )..where((p) => p.deletedAt.isNull())).getSingleOrNull();
    final goals =
        await (_db.select(_db.goals)
              ..where((g) => g.deletedAt.isNull())
              ..orderBy([(g) => OrderingTerm.asc(g.startedAt)]))
            .get();
    final weights =
        await (_db.select(_db.weightLogs)
              ..where((w) => w.deletedAt.isNull())
              ..orderBy([(w) => OrderingTerm.asc(w.day)]))
            .get();
    final meals =
        await (_db.select(_db.mealEntries)
              ..where((m) => m.deletedAt.isNull())
              ..orderBy([(m) => OrderingTerm.asc(m.eatenAt)]))
            .get();
    final savedMeals =
        await (_db.select(_db.savedMeals)
              ..where((s) => s.deletedAt.isNull())
              ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
            .get();
    final savedItems =
        await (_db.select(_db.savedMealItems)
              ..where((i) => i.deletedAt.isNull())
              ..orderBy([(i) => OrderingTerm.asc(i.sortOrder)]))
            .get();
    final samples =
        await (_db.select(_db.healthSamples)
              ..where((h) => h.deletedAt.isNull())
              ..orderBy([(h) => OrderingTerm.asc(h.measuredAt)]))
            .get();

    final workouts =
        await (_db.select(_db.workoutSessions)
              ..where((w) => w.deletedAt.isNull())
              ..orderBy([(w) => OrderingTerm.asc(w.startedAt)]))
            .get();

    final itemsByMeal = <String, List<SavedMealItemRow>>{};
    for (final item in savedItems) {
      (itemsByMeal[item.savedMealId] ??= []).add(item);
    }

    final jsonMap = <String, Object?>{
      'app': 'AURA FIT AI',
      'exported_at': exportedAt,
      'profile': profile == null
          ? null
          : {
              'birth_date': _dates.toSql(profile.birthDate),
              'sex': profile.sex?.storage,
              'height_cm': profile.heightCm,
              'activity_level': profile.activityLevel.storage,
              'diet_type': profile.dietType?.storage,
              'training_place': profile.trainingPlace?.storage,
              'experience': profile.experience?.storage,
              'training_days': profile.trainingDays,
              'created_at': profile.createdAt.toUtc().toIso8601String(),
              'updated_at': profile.updatedAt.toUtc().toIso8601String(),
            },
      'goals': [
        for (final g in goals)
          {
            'id': g.id,
            'goal_type': g.goalType.storage,
            'target_weight_kg': g.targetWeightKg,
            'basis_weight_kg': g.basisWeightKg,
            'calories_kcal': g.caloriesKcal,
            'protein_g': g.proteinG,
            'carbs_g': g.carbsG,
            'fat_g': g.fatG,
            'water_ml': g.waterMl,
            'steps': g.steps,
            'formula_version': g.formulaVersion,
            'started_at': g.startedAt.toUtc().toIso8601String(),
            'ended_at': g.endedAt?.toUtc().toIso8601String(),
          },
      ],
      'weight_logs': [
        for (final w in weights)
          {'id': w.id, 'day': _dates.toSql(w.day), 'weight_kg': w.weightKg},
      ],
      'meal_entries': [
        for (final m in meals)
          {
            'id': m.id,
            'day': _dates.toSql(m.day),
            'meal': m.meal.storage,
            'name': m.name,
            'food_id': m.foodId,
            'portion_unit': m.portionUnit,
            'portion_count': m.portionCount,
            'oil_level': m.oilLevel?.storage,
            'grams': m.grams,
            'kcal': m.kcal,
            'protein_g': m.proteinG,
            'carbs_g': m.carbsG,
            'fat_g': m.fatG,
            'source': m.source.storage,
            'eaten_at': m.eatenAt.toUtc().toIso8601String(),
          },
      ],
      'saved_meals': [
        for (final sm in savedMeals)
          {
            'id': sm.id,
            'name': sm.name,
            'items': [
              for (final item
                  in itemsByMeal[sm.id] ?? const <SavedMealItemRow>[])
                {
                  'id': item.id,
                  'name': item.name,
                  'food_id': item.foodId,
                  'portion_unit': item.portionUnit,
                  'portion_count': item.portionCount,
                  'oil_level': item.oilLevel?.storage,
                  'grams': item.grams,
                  'kcal': item.kcal,
                  'protein_g': item.proteinG,
                  'carbs_g': item.carbsG,
                  'fat_g': item.fatG,
                },
            ],
          },
      ],
      'health_samples': [
        for (final h in samples)
          {
            'id': h.id,
            'day': _dates.toSql(h.day),
            'metric': h.metric.storage,
            'value': h.value,
            'source': h.source.storage,
            'measured_at': h.measuredAt.toUtc().toIso8601String(),
          },
      ],
      'workouts': [
        for (final w in workouts)
          {
            'id': w.id,
            'day': _dates.toSql(w.day),
            'workout': w.workoutKey,
            'title': w.title,
            'sets_done': w.setsDone,
            'sets_planned': w.setsPlanned,
            'duration_min': w.durationMin,
            'started_at': w.startedAt.toUtc().toIso8601String(),
            'finished_at': w.finishedAt?.toUtc().toIso8601String(),
            'sets': jsonDecode(w.sets),
          },
      ],
    };

    final csv = StringBuffer()
      ..writeln(
        'kind,day,time_utc,category,name,amount,unit,oil_level,'
        'kcal,protein_g,carbs_g,fat_g,extra',
      );
    if (profile != null) {
      csv.writeln(
        _csvRow([
          'profile',
          _dates.toSql(profile.birthDate),
          profile.updatedAt.toUtc().toIso8601String(),
          profile.activityLevel.storage,
          profile.sex?.storage ?? '',
          profile.heightCm,
          'cm',
          '',
          '',
          '',
          '',
          '',
          profile.dietType?.storage ?? '',
        ]),
      );
    }
    for (final g in goals) {
      csv.writeln(
        _csvRow([
          'goal',
          _dates.toSql(g.startedAt.toLocal()),
          g.startedAt.toUtc().toIso8601String(),
          g.goalType.storage,
          g.formulaVersion,
          g.basisWeightKg,
          'kg',
          '',
          g.caloriesKcal,
          g.proteinG,
          g.carbsG,
          g.fatG,
          'water_ml=${g.waterMl};steps=${g.steps};ended=${g.endedAt?.toUtc().toIso8601String() ?? ''}',
        ]),
      );
    }
    for (final w in weights) {
      csv.writeln(
        _csvRow([
          'weight',
          _dates.toSql(w.day),
          w.updatedAt.toUtc().toIso8601String(),
          'weight_kg',
          'Weigh-in',
          w.weightKg,
          'kg',
          '',
          '',
          '',
          '',
          '',
          '',
        ]),
      );
    }
    for (final m in meals) {
      csv.writeln(
        _csvRow([
          'meal',
          _dates.toSql(m.day),
          m.eatenAt.toUtc().toIso8601String(),
          m.meal.storage,
          m.name,
          m.portionCount ?? m.grams,
          m.portionUnit ?? 'g',
          m.oilLevel?.storage ?? '',
          m.kcal,
          m.proteinG,
          m.carbsG,
          m.fatG,
          'grams=${m.grams};source=${m.source.storage}',
        ]),
      );
    }
    for (final h in samples) {
      csv.writeln(
        _csvRow([
          'health',
          _dates.toSql(h.day),
          h.measuredAt.toUtc().toIso8601String(),
          h.metric.storage,
          h.metric.label,
          h.value,
          h.metric == HealthMetric.waterMl ? 'ml' : 'steps',
          '',
          '',
          '',
          '',
          '',
          h.source.storage,
        ]),
      );
    }
    for (final w in workouts) {
      csv.writeln(
        _csvRow([
          'workout',
          _dates.toSql(w.day),
          w.startedAt.toUtc().toIso8601String(),
          w.workoutKey,
          w.title,
          w.setsDone,
          'sets',
          '',
          '',
          '',
          '',
          '',
          '${w.setsPlanned} planned, ${w.durationMin ?? 0} min',
        ]),
      );
    }

    return [
      ExportedFile(
        name: 'aurafit-export.json',
        content: const JsonEncoder.withIndent('  ').convert(jsonMap),
      ),
      ExportedFile(name: 'aurafit-export.csv', content: csv.toString()),
    ];
  });

  static String _csvRow(List<Object?> cells) =>
      cells.map((cell) => _escapeCsv('${cell ?? ''}')).join(',');

  static String _escapeCsv(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

final dataExporterProvider = Provider<DataExporter>(
  (ref) => DataExporter(ref.watch(appDatabaseProvider)),
);
