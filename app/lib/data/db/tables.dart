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
/// Their CHECK limits match the server's too. A row the phone accepts but
/// the server refuses could never sync, and would wait to be saved forever.
///
/// Rows are ready for sync from the start: ids are UUIDv7 made here, every
/// change stamps updatedAt, and deletes only set deletedAt.
mixin Synced on Table {
  /// Changed on this phone since it was last sent to the account's copy.
  /// New rows are; rows that came from the server aren't. Every save here
  /// sets it.
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
}

/// The shared food catalogue, bundled inside the app so search works from the
/// first minute offline and kept current by sequence number (`seq`).
@DataClassName('FoodRow')
@TableIndex(name: 'foods_name', columns: {#name})
class Foods extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// JSON list of Hindi, Hinglish and regional names.
  TextColumn get aliasesJson => text().withDefault(const Constant('[]'))();
  RealColumn get kcalPer100g => real()
      .named('kcal_per_100g')
      .check(kcalPer100g.isBetweenValues(0, 900))();
  RealColumn get proteinGPer100g => real()
      .named('protein_g_per_100g')
      .check(proteinGPer100g.isBetweenValues(0, 100))();
  RealColumn get carbsGPer100g => real()
      .named('carbs_g_per_100g')
      .check(carbsGPer100g.isBetweenValues(0, 100))();
  RealColumn get fatGPer100g => real()
      .named('fat_g_per_100g')
      .check(fatGPer100g.isBetweenValues(0, 100))();

  /// JSON list of portions, like `[{"unit":"katori","grams":150}]`.
  TextColumn get portionsJson => text().withDefault(const Constant('[]'))();

  /// What the recipe assumes, such as `"30 g wheat atta, no ghee"`.
  TextColumn get assumption =>
      text().withDefault(const Constant('')).withLength(min: 0, max: 300)();

  /// Where the numbers come from, such as `'usda_fdc'`, `'recipe'`, `'label'`.
  TextColumn get source => text().withLength(min: 1, max: 40)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get seq => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (protein_g_per_100g + carbs_g_per_100g + fat_g_per_100g <= 100.5)',
  ];
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
  RealColumn get heightCm => real().check(heightCm.isBetweenValues(100, 250))();
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
  RealColumn get targetWeightKg =>
      real().nullable().check(targetWeightKg.isBetweenValues(20, 400))();

  /// The weight the targets were worked out from, so they can be
  /// explained later.
  RealColumn get basisWeightKg =>
      real().check(basisWeightKg.isBetweenValues(20, 400))();

  /// Never below the lowest floor, as on the server.
  IntColumn get caloriesKcal =>
      integer().check(caloriesKcal.isBetweenValues(1200, 10000))();
  IntColumn get proteinG => integer().check(proteinG.isBiggerOrEqualValue(0))();
  IntColumn get carbsG => integer().check(carbsG.isBiggerOrEqualValue(0))();
  IntColumn get fatG => integer().check(fatG.isBiggerOrEqualValue(0))();
  IntColumn get waterMl => integer().check(waterMl.isBiggerThanValue(0))();
  IntColumn get steps => integer().check(steps.isBiggerThanValue(0))();
  TextColumn get formulaVersion => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (ended_at IS NULL OR ended_at >= started_at)',
  ];
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
  RealColumn get weightKg => real().check(weightKg.isBetweenValues(20, 400))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Everything eaten. Nutrients are stored with the entry so later recipe
/// fixes never rewrite past logs, and the chosen portion and oil level stay
/// for editing and repeating.
@DataClassName('MealEntryRow')
@TableIndex(name: 'meal_entries_eaten_at', columns: {#eatenAt})
@TableIndex(name: 'meal_entries_day', columns: {#day})
class MealEntries extends Table with Synced {
  TextColumn get id => text()();

  /// The catalogue food, if it came from one.
  TextColumn get foodId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get meal => text().map(const OptionConverter<Meal>(Meal.values))();

  /// The diary day this meal counts towards, so a late-night log or travel
  /// never moves it to another day.
  TextColumn get day => text().map(const DateConverter())();

  /// The portion chosen, like `'katori'` or `'piece'`, when applicable.
  TextColumn get portionUnit => text().nullable().withLength(min: 1, max: 40)();
  RealColumn get portionCount => real().nullable().check(
    portionCount.isBiggerThanValue(0) &
        portionCount.isSmallerOrEqualValue(5000),
  )();
  TextColumn get oilLevel =>
      text().nullable().map(const OptionConverter<OilLevel>(OilLevel.values))();
  RealColumn get grams => real().check(
    grams.isBiggerThanValue(0) & grams.isSmallerOrEqualValue(5000),
  )();
  RealColumn get kcal => real().check(kcal.isBetweenValues(0, 10000))();
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

/// A named favourite or meal combo, such as `"Hostel breakfast"`, synced
/// across phones.
@DataClassName('SavedMealRow')
class SavedMeals extends Table with Synced {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One dish inside a [SavedMeals] combo. Keeps the dish's name and nutrients
/// so it still works even if the shared catalogue later retires the food.
@DataClassName('SavedMealItemRow')
@TableIndex(name: 'saved_meal_items_meal', columns: {#savedMealId, #sortOrder})
class SavedMealItems extends Table with Synced {
  TextColumn get id => text()();
  TextColumn get savedMealId => text()();
  TextColumn get foodId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get portionUnit => text().nullable().withLength(min: 1, max: 40)();
  RealColumn get portionCount => real().nullable().check(
    portionCount.isBiggerThanValue(0) &
        portionCount.isSmallerOrEqualValue(5000),
  )();
  TextColumn get oilLevel =>
      text().nullable().map(const OptionConverter<OilLevel>(OilLevel.values))();
  RealColumn get grams => real().check(
    grams.isBiggerThanValue(0) & grams.isSmallerOrEqualValue(5000),
  )();
  RealColumn get kcal => real().check(kcal.isBetweenValues(0, 10000))();
  RealColumn get proteinG => real().check(proteinG.isBiggerOrEqualValue(0))();
  RealColumn get carbsG => real().check(carbsG.isBiggerOrEqualValue(0))();
  RealColumn get fatG => real().check(fatG.isBiggerOrEqualValue(0))();
  IntColumn get sortOrder => integer()
      .withDefault(const Constant(0))
      .check(sortOrder.isBetweenValues(0, 200))();
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

/// Water and steps, one row per reading, tied to its diary [day].
@DataClassName('HealthSampleRow')
@TableIndex(name: 'health_samples_metric_time', columns: {#metric, #measuredAt})
@TableIndex(name: 'health_samples_day_metric', columns: {#day, #metric})
class HealthSamples extends Table with Synced {
  TextColumn get id => text()();
  TextColumn get metric =>
      text().map(const OptionConverter<HealthMetric>(HealthMetric.values))();
  TextColumn get day => text().map(const DateConverter())();
  RealColumn get value => real().check(value.isBiggerOrEqualValue(0))();
  DateTimeColumn get measuredAt => dateTime()();
  TextColumn get source =>
      text().map(const OptionConverter<SampleSource>(SampleSource.values))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  /// The same ceiling per metric as the server, which catches a mistyped
  /// extra zero.
  @override
  List<String> get customConstraints => [
    "CHECK ((metric = 'water_ml' AND value <= 5000) "
        "OR (metric = 'steps' AND value <= 100000))",
  ];
}
