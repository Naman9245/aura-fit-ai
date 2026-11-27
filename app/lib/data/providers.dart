import 'package:aurafit/core/error_reporter.dart';
import 'package:aurafit/data/account_data.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/food_repository.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/data/workout_repository.dart';
import 'package:aurafit/services/workouts.dart';
import 'package:aurafit/services/meal_text_parser.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone's database. Tests override it with an in-memory one.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// The "Send crash reports" switch. Tests override it with a fake.
final crashReportsProvider = Provider<CrashReportSwitch>((ref) => crashReports);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(appDatabaseProvider)),
);

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(ref.watch(appDatabaseProvider)),
);

final logRepositoryProvider = Provider<LogRepository>(
  (ref) => LogRepository(ref.watch(appDatabaseProvider)),
);

final mealParseRemoteProvider = Provider<MealParseRemote>(
  (ref) => SupabaseMealParseRemote(),
);

final mealTextParserProvider = Provider<MealTextParser>(
  (ref) => MealTextParser(
    ref.watch(foodRepositoryProvider),
    ref.watch(mealParseRemoteProvider),
  ),
);

final accountDataProvider = Provider<AccountData>(
  (ref) => AccountData(ref.watch(appDatabaseProvider)),
);

/// The account this phone's data belongs to, once it has synced; it stays
/// known while signed out, until signing out takes the data off the phone.
final phoneOwnerProvider = StreamProvider<SyncAccountRow?>(
  (ref) => ref.watch(accountDataProvider).watchOwner(),
);

/// The active profile row, kept up to date.
final profileProvider = StreamProvider<ProfileRow?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(
    db.profiles,
  )..where((p) => p.deletedAt.isNull())).watchSingleOrNull();
});

/// The active goal with the working behind it, kept up to date.
final explainedGoalProvider = StreamProvider<ExplainedGoal?>(
  (ref) => ref.watch(profileRepositoryProvider).watchExplainedGoal(),
);

/// Live summary of meals, water, steps and weigh-in for a diary [DateTime].
final daySummaryProvider = StreamProvider.family<DaySummary, DateTime>(
  (ref, day) => ref.watch(logRepositoryProvider).watchDay(day),
);

/// Live 7-day rolling calorie and protein average ending on [DateTime].
final sevenDayAverageProvider =
    StreamProvider.family<SevenDayAverage, DateTime>(
      (ref, endDay) =>
          ref.watch(logRepositoryProvider).watchSevenDayAverage(endDay),
    );

/// Live saved meals / favourites.
final savedMealsProvider = StreamProvider<List<SavedMealBundle>>(
  (ref) => ref.watch(logRepositoryProvider).watchSavedMeals(),
);

/// Every day with a meal logged.
final mealDaysProvider = StreamProvider<Set<DateTime>>(
  (ref) => ref.watch(logRepositoryProvider).watchLoggedDays(),
);

/// Every day with a meal or a workout logged: Josh's streak and the
/// Progress calendar.
final loggedDaysProvider = Provider<AsyncValue<Set<DateTime>>>((ref) {
  final meals = ref.watch(mealDaysProvider).value;
  final workouts = ref.watch(workoutDaysProvider).value;
  return AsyncData({...?meals, ...?workouts});
});

/// How far back the weight trend looks: 12 weeks.
const weightTrendDays = 84;

/// Weigh-ins over the last [weightTrendDays], oldest first (PRD D3).
final weighInsProvider = StreamProvider<List<WeightLogRow>>((ref) {
  final today = diaryDay(clock.now());
  final from = DateTime(
    today.year,
    today.month,
    today.day - weightTrendDays + 1,
  );
  return ref.watch(logRepositoryProvider).watchWeighIns(from: from);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(appDatabaseProvider)),
);

/// This week's training plan, or null until where and how often to train
/// are chosen.
final trainingPlanProvider = Provider<TrainingPlan?>((ref) {
  final profile = ref.watch(profileProvider).value;
  final place = profile?.trainingPlace;
  if (place == null) return null;
  return TrainingPlan(
    place: place,
    days: profile?.trainingDays ?? suggestedDays(profile?.experience),
    experience: profile?.experience,
  );
});

/// Workouts done in the week (Monday to Sunday) that holds a day.
final weekWorkoutsProvider =
    StreamProvider.family<List<WorkoutSessionRow>, DateTime>((ref, day) {
      final d = diaryDay(day);
      final monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
      final sunday = DateTime(monday.year, monday.month, monday.day + 6);
      return ref.watch(workoutRepositoryProvider).watchBetween(monday, sunday);
    });

/// Every day with a workout, for the calendar and the goals.
final workoutDaysProvider = StreamProvider<Set<DateTime>>(
  (ref) => ref.watch(workoutRepositoryProvider).watchWorkoutDays(),
);

/// Recent distinct dishes for thumb-reach re-logging.
final recentFoodsProvider = StreamProvider<List<MealEntryRow>>(
  (ref) => ref.watch(logRepositoryProvider).watchRecentFoods(),
);
