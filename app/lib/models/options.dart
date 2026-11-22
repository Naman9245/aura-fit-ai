/// The fixed choices a profile is made of.
///
/// Each option is stored by its [StoredOption.storage] string, on the phone
/// and in Postgres alike, and the server's CHECK constraints list the same
/// strings. Renaming a Dart value can't change what's stored, and an unknown
/// string is refused rather than guessed at.
library;

/// An option saved by a fixed string.
abstract interface class StoredOption {
  /// What the database holds for this option.
  String get storage;

  /// How the app names it.
  String get label;
}

/// The option of [values] saved as [storage].
///
/// Throws an [ArgumentError] for anything else: a value written by a newer
/// app, or by hand, must not quietly become a different choice.
T parseOption<T extends StoredOption>(List<T> values, String storage) {
  for (final value in values) {
    if (value.storage == storage) return value;
  }
  throw ArgumentError.value(storage, 'storage', 'Not a known $T');
}

/// Sex as the calorie formula uses it. Someone who'd rather not say has no
/// value, and the formula then takes the midpoint.
enum Sex implements StoredOption {
  female('female', 'Female'),
  male('male', 'Male');

  const Sex(this.storage, this.label);

  @override
  final String storage;
  @override
  final String label;
}

enum ActivityLevel implements StoredOption {
  sedentary('sedentary', 'Mostly sitting', 'A desk job and little exercise'),
  lightlyActive(
    'lightly_active',
    'Lightly active',
    'Light exercise 1 to 3 days a week',
  ),
  active('active', 'Active', 'Exercise 3 to 5 days a week'),
  athlete(
    'athlete',
    'Very active',
    'Hard training 6 or 7 days a week, or a physical job',
  );

  const ActivityLevel(this.storage, this.label, this.description);

  @override
  final String storage;
  @override
  final String label;
  final String description;
}

enum GoalType implements StoredOption {
  loseFat(
    'lose_fat',
    'Lose fat',
    'Eat a steady 500 kcal a day below maintenance',
  ),
  gainMuscle(
    'gain_muscle',
    'Gain muscle',
    'Eat 300 kcal above maintenance, with plenty of protein',
  ),
  recomposition(
    'recomposition',
    'Lose fat and build muscle',
    'A gentle 200 kcal below maintenance, with plenty of protein',
  ),
  maintain('maintain', 'Stay where I am', 'Eat what your body uses'),
  performance(
    'performance',
    'Train for a sport',
    'Eat 250 kcal above maintenance to fuel training',
  );

  const GoalType(this.storage, this.label, this.description);

  @override
  final String storage;
  @override
  final String label;
  final String description;
}

enum DietType implements StoredOption {
  veg('veg', 'Vegetarian'),
  egg('egg', 'Vegetarian, with eggs'),
  nonVeg('non_veg', 'Non-vegetarian'),
  vegan('vegan', 'Vegan');

  const DietType(this.storage, this.label);

  @override
  final String storage;
  @override
  final String label;
}

enum TrainingPlace implements StoredOption {
  gym('gym', 'At a gym'),
  dumbbells('dumbbells', 'At home, with dumbbells'),
  home('home', 'At home, no equipment');

  const TrainingPlace(this.storage, this.label);

  @override
  final String storage;
  @override
  final String label;
}

/// Which meal an entry belongs to, so a whole meal can be logged again.
enum Meal implements StoredOption {
  breakfast('breakfast', 'Breakfast'),
  lunch('lunch', 'Lunch'),
  dinner('dinner', 'Dinner'),
  snack('snack', 'Snack');

  const Meal(this.storage, this.label);

  @override
  final String storage;
  @override
  final String label;
}

/// How a meal entry was logged.
enum EntrySource implements StoredOption {
  search('search', 'Search'),
  text('text', 'Typed'),
  photo('photo', 'Photo'),
  repeat('repeat', 'Repeated'),
  manual('manual', 'Entered by hand');

  const EntrySource(this.storage, this.label);

  @override
  final String storage;
  @override
  final String label;
}

/// What a health sample measures. The unit is part of the name, so no
/// reading can be in the wrong one.
enum HealthMetric implements StoredOption {
  waterMl('water_ml', 'Water'),
  steps('steps', 'Steps');

  const HealthMetric(this.storage, this.label);

  @override
  final String storage;
  @override
  final String label;
}

/// Where a health sample came from. Health Connect joins after launch.
enum SampleSource implements StoredOption {
  manual('manual', 'Entered by hand');

  const SampleSource(this.storage, this.label);

  @override
  final String storage;
  @override
  final String label;
}

enum Experience implements StoredOption {
  beginner('beginner', 'New to training'),
  intermediate('intermediate', 'Training for a year or more'),
  advanced('advanced', 'Training for several years');

  const Experience(this.storage, this.label);

  @override
  final String storage;
  @override
  final String label;
}
