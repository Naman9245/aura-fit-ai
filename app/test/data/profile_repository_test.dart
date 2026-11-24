import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The 889 kcal case from the old backend: 50 kg, 155 cm, 30 years old,
/// sitting most of the day, losing fat.
final _answers = ProfileAnswers(
  goal: GoalType.loseFat,
  birthDate: DateTime(1996, 5, 10),
  sex: Sex.female,
  heightCm: 155,
  weightKg: 50,
  activity: ActivityLevel.sedentary,
  diet: DietType.veg,
);

ProfileAnswers _withWeight(double weightKg) => ProfileAnswers(
  goal: _answers.goal,
  birthDate: _answers.birthDate,
  sex: _answers.sex,
  heightCm: _answers.heightCm,
  weightKg: weightKg,
  activity: _answers.activity,
  diet: _answers.diet,
);

void main() {
  late AppDatabase db;
  late ProfileRepository repo;
  final day1 = DateTime(2026, 11, 22, 9, 30);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ProfileRepository(db);
  });
  tearDown(() => db.close());

  Future<GoalRow> saveAt(DateTime time, ProfileAnswers answers) =>
      withClock(Clock.fixed(time), () => repo.saveProfile(answers));

  group('first save', () {
    test('stores the profile, today\'s weight and safe targets', () async {
      final goal = await saveAt(day1, _answers);

      final profile = (await repo.profile())!;
      expect(profile.birthDate, DateTime(1996, 5, 10));
      expect(profile.sex, Sex.female);
      expect(profile.heightCm, 155);
      expect(profile.activityLevel, ActivityLevel.sedentary);
      expect(profile.dietType, DietType.veg);
      expect(profile.trainingPlace, isNull);
      expect(profile.createdAt, day1);
      expect(profile.dirty, isTrue);

      final weight = (await repo.latestWeight())!;
      expect((weight.day, weight.weightKg), (DateTime(2026, 11, 22), 50.0));

      expect(goal.goalType, GoalType.loseFat);
      expect(goal.caloriesKcal, 1200, reason: 'raised from 889 kcal');
      expect(goal.basisWeightKg, 50);
      expect(goal.formulaVersion, 'v1');
      expect(goal.startedAt, day1);
      expect(goal.endedAt, isNull);
      expect(goal.dirty, isTrue);
    });

    test(
      'rounds height and weight to 1 decimal place, as the server keeps them',
      () async {
        await saveAt(
          day1,
          ProfileAnswers(
            goal: GoalType.maintain,
            birthDate: DateTime(1990, 1, 1),
            sex: null,
            heightCm: 170.25,
            weightKg: 64.97,
            activity: ActivityLevel.active,
          ),
        );

        expect((await repo.profile())!.heightCm, 170.2);
        expect((await repo.latestWeight())!.weightKg, 65.0);
      },
    );

    test('the stored targets are the explained ones, rounded', () async {
      final goal = await saveAt(day1, _withWeight(72.4));
      final targets = repo.explain((await repo.profile())!, goal);

      expect(goal.caloriesKcal, targets.caloriesKcal.round());
      expect(goal.proteinG, targets.proteinG.round());
      expect(goal.carbsG, targets.carbsG.round());
      expect(goal.fatG, targets.fatG.round());
      expect(goal.waterMl, (targets.waterL * 1000).round());
      expect(goal.steps, targets.steps);
    });
  });

  group('editing the details', () {
    test('new targets end the old goal, which is kept', () async {
      final first = await saveAt(day1, _answers);
      final later = day1.add(const Duration(days: 30));
      final second = await saveAt(later, _withWeight(58));

      expect(second.id, isNot(first.id));
      expect(second.basisWeightKg, 58);
      final all = await db.select(db.goals).get();
      expect(all, hasLength(2));
      final old = all.singleWhere((g) => g.id == first.id);
      expect(old.endedAt, later);
      expect(old.updatedAt, later);
      expect(old.formulaVersion, 'v1');
    });

    test('saving the same answers again keeps the same goal', () async {
      final first = await saveAt(day1, _answers);
      final again = await saveAt(day1.add(const Duration(hours: 2)), _answers);

      expect(again.id, first.id);
      expect(await db.select(db.goals).get(), hasLength(1));
    });

    test('a second weigh-in on the same day replaces the first', () async {
      await saveAt(day1, _answers);
      await saveAt(day1.add(const Duration(hours: 3)), _withWeight(49.5));

      final weights = await db.select(db.weightLogs).get();
      expect(weights, hasLength(1));
      expect(weights.single.weightKg, 49.5);
    });

    test('a weigh-in on another day is kept beside the first', () async {
      await saveAt(day1, _answers);
      await saveAt(day1.add(const Duration(days: 1)), _withWeight(49.5));

      expect(await db.select(db.weightLogs).get(), hasLength(2));
      expect((await repo.latestWeight())!.weightKg, 49.5);
    });
  });

  group('explaining a goal', () {
    test('uses the age on the day the goal started', () async {
      // Turns 31 on 10 May 2027, after the goal started.
      final goal = await saveAt(day1, _answers);
      final profile = (await repo.profile())!;
      final targets = withClock(
        Clock.fixed(DateTime(2027, 6, 1)),
        () => repo.explain(profile, goal),
      );

      expect(targets.inputs.age, 30);
      expect(targets.caloriesKcal, goal.caloriesKcal);
    });

    test('refuses a goal made with a formula this app doesn\'t know', () async {
      final goal = await saveAt(day1, _answers);
      final profile = (await repo.profile())!;

      expect(
        () => repo.explain(profile, goal.copyWith(formulaVersion: 'v9')),
        throwsStateError,
      );
    });
  });

  group('the database itself', () {
    GoalsCompanion goal(String id, {int kcal = 2000, DateTime? endedAt}) =>
        GoalsCompanion.insert(
          id: id,
          goalType: GoalType.maintain,
          basisWeightKg: 70,
          caloriesKcal: kcal,
          proteinG: 112,
          carbsG: 250,
          fatG: 60,
          waterMl: 2450,
          steps: 8000,
          formulaVersion: 'v1',
          startedAt: day1,
          endedAt: Value(endedAt),
          createdAt: day1,
          updatedAt: day1,
        );

    test('allows only one active goal', () async {
      await db.into(db.goals).insert(goal('a'));
      await db.into(db.goals).insert(goal('ended', endedAt: day1));

      expect(
        () => db.into(db.goals).insert(goal('b')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('refuses a target below the safe floor', () async {
      expect(
        () => db.into(db.goals).insert(goal('low', kcal: 889)),
        throwsA(isA<SqliteException>()),
      );
    });

    // Each of these the server's CHECK constraints would refuse, so a row
    // like it could never sync. The phone refuses it first.
    test('refuses what the server would refuse', () async {
      final at = day1;
      final tooMuch = <String, Future<void> Function()>{
        'a 12,000 kcal goal': () =>
            db.into(db.goals).insert(goal('high', kcal: 12000)),
        '6 litres of water at once': () => db
            .into(db.healthSamples)
            .insert(
              HealthSamplesCompanion.insert(
                id: 'w',
                metric: HealthMetric.waterMl,
                value: 6000,
                measuredAt: at,
                source: SampleSource.manual,
                createdAt: at,
                updatedAt: at,
              ),
            ),
        '6 kg of food in one entry': () => db
            .into(db.mealEntries)
            .insert(
              MealEntriesCompanion.insert(
                id: 'm',
                name: 'Biryani',
                meal: Meal.dinner,
                grams: 6000,
                kcal: 900,
                proteinG: 30,
                carbsG: 100,
                fatG: 40,
                eatenAt: at,
                source: EntrySource.manual,
                createdAt: at,
                updatedAt: at,
              ),
            ),
        'a 450 kg weigh-in': () => db
            .into(db.weightLogs)
            .insert(
              WeightLogsCompanion.insert(
                id: 'x',
                day: DateTime(2026, 11, 22),
                weightKg: 450,
                createdAt: at,
                updatedAt: at,
              ),
            ),
      };
      for (final MapEntry(key: what, value: insert) in tooMuch.entries) {
        await expectLater(
          insert,
          throwsA(isA<SqliteException>()),
          reason: what,
        );
      }

      // 100,000 steps is a lot, but allowed.
      await db
          .into(db.healthSamples)
          .insert(
            HealthSamplesCompanion.insert(
              id: 's',
              metric: HealthMetric.steps,
              value: 100000,
              measuredAt: at,
              source: SampleSource.manual,
              createdAt: at,
              updatedAt: at,
            ),
          );
    });

    test('moves an edit\'s stamp forward past the one it replaces', () async {
      await db.into(db.goals).insert(goal('a'));

      // This phone's clock is a minute behind the saved stamp.
      await (db.update(db.goals)..where((g) => g.id.equals('a'))).write(
        GoalsCompanion(
          steps: const Value(9000),
          updatedAt: Value(day1.subtract(const Duration(minutes: 1))),
        ),
      );

      final row = await db.select(db.goals).getSingle();
      expect(row.updatedAt, day1.add(const Duration(seconds: 1)));
    });

    test('leaves the stamp of a row sync wrote alone', () async {
      await db.into(db.goals).insert(goal('a'));
      final older = day1.subtract(const Duration(minutes: 1));

      await (db.update(db.goals)..where((g) => g.id.equals('a'))).write(
        GoalsCompanion(updatedAt: Value(older), dirty: const Value(false)),
      );

      expect((await db.select(db.goals).getSingle()).updatedAt, older);
    });

    test('refuses an option it doesn\'t know rather than guessing', () async {
      await saveAt(day1, _answers);
      await db.customStatement("UPDATE profiles SET activity_level = 'couch'");

      expect(repo.profile, throwsArgumentError);
    });

    test('keeps dates as plain calendar dates', () async {
      await saveAt(day1, _answers);
      final raw = await db
          .customSelect('SELECT birth_date FROM profiles')
          .getSingle();

      expect(raw.read<String>('birth_date'), '1996-05-10');
    });
  });
}
