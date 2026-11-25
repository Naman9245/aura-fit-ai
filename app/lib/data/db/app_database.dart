import 'package:aurafit/data/db/app_database.steps.dart';
import 'package:aurafit/data/db/converters.dart';
import 'package:aurafit/data/db/tables.dart';
import 'package:aurafit/models/options.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Everything the app keeps on the phone. The app reads and writes only
/// here, so it works the same with no network; the server gets a copy.
@DriftDatabase(
  tables: [
    Foods,
    Profiles,
    Goals,
    WeightLogs,
    MealEntries,
    SavedMeals,
    SavedMealItems,
    HealthSamples,
    SyncCursors,
    SyncAccount,
  ],
  // Edits here always move a row's stamp forward.
  include: {'stamps.drift'},
)
class AppDatabase extends _$AppDatabase {
  /// Tests pass an in-memory executor.
  AppDatabase(super.executor);

  /// Opens `aurafit.sqlite` in the app's documents folder.
  AppDatabase.open() : super(driftDatabase(name: 'aurafit'));

  // To change the schema: bump this, add a step to [migration], then run
  // `dart run drift_dev make-migrations` so the new step gets a test.
  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      // Sync: how far each table has been read, and whose data this is.
      from1To2: (m, schema) async {
        await m.createTable(schema.syncCursors);
        await m.createTable(schema.syncAccount);
      },
      // v3: the server's CHECK limits, so nothing is saved here that the
      // server would refuse. Rebuilding a table keeps its rows.
      from2To3: (m, schema) async {
        for (final table in [
          schema.profiles,
          schema.goals,
          schema.weightLogs,
          schema.mealEntries,
          schema.healthSamples,
        ]) {
          await m.alterTable(TableMigration(table));
        }
      },
      // v4: Decisions for the code — bundled food catalogue, saved meals,
      // portion and oil level on meal entries, and diary day on meals and
      // health samples.
      from3To4: (m, schema) async {
        await m.createTable(schema.foods);
        await m.createIndex(schema.foodsName);
        await m.createTable(schema.savedMeals);
        await m.createTrigger(schema.savedMealsStampForward);
        await m.createTable(schema.savedMealItems);
        await m.createTrigger(schema.savedMealItemsStampForward);
        await m.createIndex(schema.savedMealItemsMeal);
        await m.alterTable(TableMigration(schema.goals));
        await m.alterTable(
          TableMigration(
            schema.mealEntries,
            newColumns: [
              schema.mealEntries.day,
              schema.mealEntries.portionUnit,
              schema.mealEntries.portionCount,
              schema.mealEntries.oilLevel,
            ],
            columnTransformer: {
              schema.mealEntries.day: const CustomExpression(
                "strftime('%Y-%m-%d', eaten_at, 'unixepoch', 'localtime')",
              ),
            },
          ),
        );
        await m.createIndex(schema.mealEntriesDay);
        await m.alterTable(
          TableMigration(
            schema.healthSamples,
            newColumns: [schema.healthSamples.day],
            columnTransformer: {
              schema.healthSamples.day: const CustomExpression(
                "strftime('%Y-%m-%d', measured_at, 'unixepoch', 'localtime')",
              ),
            },
          ),
        );
        await m.createIndex(schema.healthSamplesDayMetric);
      },
    ),
  );
}
