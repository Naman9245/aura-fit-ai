import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/workout_repository.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });

  tearDown(() => db.close());

  test('a workout saves with its sets, and starts the next one', () async {
    final monday = DateTime(2026, 11, 23, 18);
    await withClock(
      Clock.fixed(monday.add(const Duration(minutes: 40))),
      () async {
        await repo.saveSession(
          day: monday,
          workoutKey: 'lower_a',
          title: 'LOWER BODY A',
          startedAt: monday,
          sets: const [
            LoggedSet(exercise: 'goblet_squat', reps: 12, kg: 12, done: true),
            LoggedSet(exercise: 'goblet_squat', reps: 11, kg: 12, done: true),
            LoggedSet(exercise: 'plank', seconds: 30),
          ],
        );
      },
    );

    final week = await repo
        .watchBetween(DateTime(2026, 11, 23), DateTime(2026, 11, 29))
        .first;
    expect(week, hasLength(1));
    final row = week.single;
    expect((row.setsDone, row.setsPlanned, row.durationMin), (2, 3, 40));
    expect(row.dirty, isTrue, reason: 'it goes to the account');
    expect(setsOf(row).first.kg, 12);

    final last = await repo.lastSets('goblet_squat');
    expect(last.map((s) => s.reps), [12, 11]);
    expect(await repo.lastSets('plank'), isEmpty, reason: 'not done');
    expect(await repo.watchWorkoutDays().first, {DateTime(2026, 11, 23)});

    final undo = await repo.deleteSession(row);
    expect(
      await repo
          .watchBetween(DateTime(2026, 11, 23), DateTime(2026, 11, 29))
          .first,
      isEmpty,
    );
    await undo.undo();
    expect(await repo.watchWorkoutDays().first, hasLength(1));
  });
}
