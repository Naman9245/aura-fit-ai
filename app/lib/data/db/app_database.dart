import 'package:aurafit/data/db/converters.dart';
import 'package:aurafit/data/db/tables.dart';
import 'package:aurafit/models/options.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Everything the app keeps on the phone. The app reads and writes only
/// here, so it works the same with no network; the server gets a copy.
@DriftDatabase(
  tables: [Profiles, Goals, WeightLogs, MealEntries, HealthSamples],
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
