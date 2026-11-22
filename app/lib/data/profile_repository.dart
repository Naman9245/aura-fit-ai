import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/rounding.dart';
import 'package:aurafit/services/targets.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// A complete set of onboarding answers.
class ProfileAnswers {
  const ProfileAnswers({
    required this.goal,
    required this.birthDate,
    required this.sex,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    this.diet,
    this.trainingPlace,
    this.experience,
  });

  final GoalType goal;
  final DateTime birthDate;

  /// Null when the person would rather not say.
  final Sex? sex;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final DietType? diet;
  final TrainingPlace? trainingPlace;
  final Experience? experience;
}

/// The active goal, with the working behind its numbers.
typedef ExplainedGoal = ({GoalRow goal, Targets targets});

/// The profile, the weigh-ins and the goals, on this phone.
class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<bool> hasProfile() async => await profile() != null;

  Future<ProfileRow?> profile() => _profileQuery().getSingleOrNull();

  Stream<GoalRow?> watchActiveGoal() => _activeGoalQuery().watchSingleOrNull();

  Future<GoalRow?> activeGoal() => _activeGoalQuery().getSingleOrNull();

  /// The most recent weigh-in.
  Future<WeightLogRow?> latestWeight() =>
      (_db.select(_db.weightLogs)
            ..where((w) => w.deletedAt.isNull())
            ..orderBy([(w) => OrderingTerm.desc(w.day)])
            ..limit(1))
          .getSingleOrNull();

  /// The active goal and how its numbers were reached, kept up to date.
  Stream<ExplainedGoal?> watchExplainedGoal() =>
      watchActiveGoal().asyncMap((goal) async {
        if (goal == null) return null;
        final profile = await this.profile();
        if (profile == null) return null;
        return (goal: goal, targets: explain(profile, goal));
      });

  /// Works the goal's numbers out again, the way they were reached: with
  /// its own weight and goal type, and the age on the day it started.
  Targets explain(ProfileRow profile, GoalRow goal) {
    if (goal.formulaVersion != formulaVersion) {
      throw StateError(
        'Goal ${goal.id} uses formula ${goal.formulaVersion}, '
        'and only $formulaVersion is known',
      );
    }
    final started = goal.startedAt.toLocal();
    return calculateTargets(
      TargetInputs(
        age: ageOn(
          profile.birthDate,
          DateTime(started.year, started.month, started.day),
        ),
        sex: profile.sex,
        heightCm: profile.heightCm,
        weightKg: goal.basisWeightKg,
        activity: profile.activityLevel,
        goal: goal.goalType,
      ),
    );
  }

  /// Saves what onboarding collected, all at once: the profile, today's
  /// weight and new targets. Editing the details saves through here too;
  /// when the targets come out different, the old goal ends and stays.
  Future<GoalRow> saveProfile(ProfileAnswers answers) =>
      _db.transaction(() async {
        final now = clock.now();
        final today = DateTime(now.year, now.month, now.day);
        // Stored to 1 decimal place, as the server's numeric(4, 1) holds them.
        final heightCm = roundHalfEven(answers.heightCm, 1);
        final weightKg = roundHalfEven(answers.weightKg, 1);

        final existing = await profile();
        final profileRow = ProfilesCompanion(
          birthDate: Value(answers.birthDate),
          sex: Value(answers.sex),
          heightCm: Value(heightCm),
          activityLevel: Value(answers.activity),
          dietType: Value(answers.diet),
          trainingPlace: Value(answers.trainingPlace),
          experience: Value(answers.experience),
          updatedAt: Value(now),
          dirty: const Value(true),
        );
        if (existing == null) {
          await _db
              .into(_db.profiles)
              .insert(profileRow.copyWith(createdAt: Value(now)));
        } else {
          await _db.update(_db.profiles).write(profileRow);
        }

        await _saveWeight(today, weightKg, now);

        final targets = calculateTargets(
          TargetInputs(
            age: ageOn(answers.birthDate, today),
            sex: answers.sex,
            heightCm: heightCm,
            weightKg: weightKg,
            activity: answers.activity,
            goal: answers.goal,
          ),
        );
        final newGoal = GoalsCompanion.insert(
          id: _uuid.v7(),
          goalType: answers.goal,
          basisWeightKg: weightKg,
          caloriesKcal: _whole(targets.caloriesKcal),
          proteinG: _whole(targets.proteinG),
          carbsG: _whole(targets.carbsG),
          fatG: _whole(targets.fatG),
          waterMl: _whole(targets.waterL * 1000),
          steps: targets.steps,
          formulaVersion: targets.version,
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        );

        final active = await activeGoal();
        if (active != null) {
          if (_sameTargets(active, newGoal)) return active;
          await (_db.update(
            _db.goals,
          )..where((g) => g.id.equals(active.id))).write(
            GoalsCompanion(
              endedAt: Value(now),
              updatedAt: Value(now),
              dirty: const Value(true),
            ),
          );
        }
        await _db.into(_db.goals).insert(newGoal);
        return (await activeGoal())!;
      });

  /// One weigh-in a day: a second one today replaces the first.
  Future<void> _saveWeight(
    DateTime today,
    double weightKg,
    DateTime now,
  ) async {
    final todays =
        await (_db.select(_db.weightLogs)
              ..where((w) => w.day.equalsValue(today) & w.deletedAt.isNull()))
            .getSingleOrNull();
    if (todays == null) {
      await _db
          .into(_db.weightLogs)
          .insert(
            WeightLogsCompanion.insert(
              id: _uuid.v7(),
              day: today,
              weightKg: weightKg,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else if (todays.weightKg != weightKg) {
      await (_db.update(
        _db.weightLogs,
      )..where((w) => w.id.equals(todays.id))).write(
        WeightLogsCompanion(
          weightKg: Value(weightKg),
          updatedAt: Value(now),
          dirty: const Value(true),
        ),
      );
    }
  }

  SimpleSelectStatement<$ProfilesTable, ProfileRow> _profileQuery() =>
      _db.select(_db.profiles)..where((p) => p.deletedAt.isNull());

  SimpleSelectStatement<$GoalsTable, GoalRow> _activeGoalQuery() =>
      _db.select(_db.goals)
        ..where((g) => g.endedAt.isNull() & g.deletedAt.isNull());
}

int _whole(double x) => roundHalfEven(x, 0).toInt();

bool _sameTargets(GoalRow active, GoalsCompanion next) =>
    active.goalType == next.goalType.value &&
    active.basisWeightKg == next.basisWeightKg.value &&
    active.caloriesKcal == next.caloriesKcal.value &&
    active.proteinG == next.proteinG.value &&
    active.carbsG == next.carbsG.value &&
    active.fatG == next.fatG.value &&
    active.waterMl == next.waterMl.value &&
    active.steps == next.steps.value &&
    active.formulaVersion == next.formulaVersion.value;
