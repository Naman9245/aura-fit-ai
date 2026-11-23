// Drift reads these getters as a description of the schema. A check like
// `id.equals(1)` inside `id` becomes `CHECK (id = 1)`, not a call.
// ignore_for_file: recursive_getters

import 'package:aurafit/data/db/converters.dart';
import 'package:aurafit/models/options.dart';
import 'package:drift/drift.dart';

/// The phone's copy of a person's own data. Each table matches its
/// Postgres table in supabase/migrations, apart from user_id and seq,
/// which only the server keeps: this phone holds one person's rows.
///
/// Rows are ready for sync from the start: ids are UUIDv7 made here, every
/// change stamps updatedAt, and deletes only set deletedAt.
mixin Synced on Table {
  /// Changed on this phone since it was last sent to the account's copy.
  /// New rows are; rows that came from the server aren't. Every save here
  /// sets it.
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}

/// The person's profile: everything the targets are worked out from,
/// apart from weight.
@DataClassName('ProfileRow')
class Profiles extends Table with Synced {
  /// Always 1. There is one profile on a phone, as there is one per
  /// account, which the server keys it by.
  IntColumn get id =>
      integer().withDefault(const Constant(1)).check(id.equals(1))();
  TextColumn get birthDate => text().map(const DateConverter())();

  /// Null when the person would rather not say.
  TextColumn get sex =>
      text().nullable().map(const OptionConverter<Sex>(Sex.values))();
  RealColumn get heightCm => real()();
  TextColumn get activityLevel =>
      text().map(const OptionConverter<ActivityLevel>(ActivityLevel.values))();

  /// The next three can be skipped.
  TextColumn get dietType =>
      text().nullable().map(const OptionConverter<DietType>(DietType.values))();
  TextColumn get trainingPlace => text().nullable().map(
    const OptionConverter<TrainingPlace>(TrainingPlace.values),
  )();
  TextColumn get experience => text().nullable().map(
    const OptionConverter<Experience>(Experience.values),
  )();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Daily targets. The active goal has no [endedAt]; a new goal ends it,
/// and the old one stays with the formula version it was worked out with.
@DataClassName('GoalRow')
// Every row in this partial index has `ended_at IS NULL` true, so making
// that expression unique allows one active goal.
@TableIndex.sql(
  'CREATE UNIQUE INDEX goals_one_active ON goals ((ended_at IS NULL)) '
  'WHERE ended_at IS NULL AND deleted_at IS NULL',
)
class Goals extends Table with Synced {
  TextColumn get id => text()();
  TextColumn get goalType =>
      text().map(const OptionConverter<GoalType>(GoalType.values))();
  RealColumn get targetWeightKg => real().nullable()();

  /// The weight the targets were worked out from, so they can be
  /// explained later.
  RealColumn get basisWeightKg => real()();

  /// Never below the lowest floor, as on the server.
  IntColumn get caloriesKcal =>
      integer().check(caloriesKcal.isBiggerOrEqualValue(1200))();
  IntColumn get proteinG => integer()();
  IntColumn get carbsG => integer()();
  IntColumn get fatG => integer()();
  IntColumn get waterMl => integer()();
  IntColumn get steps => integer()();
  TextColumn get formulaVersion => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One weight a day, on the day as the person lived it.
@DataClassName('WeightLogRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX weight_logs_one_a_day ON weight_logs (day) '
  'WHERE deleted_at IS NULL',
)
class WeightLogs extends Table with Synced {
  TextColumn get id => text()();
  TextColumn get day => text().map(const DateConverter())();
  RealColumn get weightKg => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Everything eaten. Nutrients are for the amount eaten. Logging starts
/// in January.
@DataClassName('MealEntryRow')
@TableIndex(name: 'meal_entries_eaten_at', columns: {#eatenAt})
class MealEntries extends Table with Synced {
  TextColumn get id => text()();

  /// The catalogue food, if it came from one.
  TextColumn get foodId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get meal => text().map(const OptionConverter<Meal>(Meal.values))();
  RealColumn get grams => real().check(grams.isBiggerThanValue(0))();
  RealColumn get kcal => real().check(kcal.isBiggerOrEqualValue(0))();
  RealColumn get proteinG => real().check(proteinG.isBiggerOrEqualValue(0))();
  RealColumn get carbsG => real().check(carbsG.isBiggerOrEqualValue(0))();
  RealColumn get fatG => real().check(fatG.isBiggerOrEqualValue(0))();
  DateTimeColumn get eatenAt => dateTime()();
  TextColumn get source =>
      text().map(const OptionConverter<EntrySource>(EntrySource.values))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// How far this phone has read each table of the account's copy: the last
/// change number it applied.
@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  /// The table, by its name on both sides.
  TextColumn get kind => text()();
  IntColumn get seq => integer()();

  @override
  Set<Column<Object>> get primaryKey => {kind};
}

/// The account this phone's data belongs to, once it has synced with one.
/// Signing out removes it along with the data, so the next account starts
/// from nothing; until then no other account can sync these rows.
@DataClassName('SyncAccountRow')
class SyncAccount extends Table {
  /// Always 1: a phone's data belongs to one account at a time.
  IntColumn get id =>
      integer().withDefault(const Constant(1)).check(id.equals(1))();
  TextColumn get accountId => text()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get boundAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Water and steps, one row per reading. Logging starts in January.
@DataClassName('HealthSampleRow')
@TableIndex(name: 'health_samples_metric_time', columns: {#metric, #measuredAt})
class HealthSamples extends Table with Synced {
  TextColumn get id => text()();
  TextColumn get metric =>
      text().map(const OptionConverter<HealthMetric>(HealthMetric.values))();
  RealColumn get value => real().check(value.isBiggerOrEqualValue(0))();
  DateTimeColumn get measuredAt => dateTime()();
  TextColumn get source =>
      text().map(const OptionConverter<SampleSource>(SampleSource.values))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
