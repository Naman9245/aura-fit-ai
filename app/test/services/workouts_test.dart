import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/workouts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Sunday is always rest, and the other days off are active rest', () {
    for (final place in TrainingPlace.values) {
      for (var days = 3; days <= 6; days++) {
        final plan = TrainingPlan(place: place, days: days, experience: null);
        expect(plan.dayOf(DateTime.sunday), isA<RestDay>());
        final training = [
          for (var weekday = 1; weekday <= 7; weekday++)
            if (plan.dayOf(weekday) is TrainingDay) weekday,
        ];
        expect(training, hasLength(days), reason: '$place, $days days');
        for (var weekday = 1; weekday < 7; weekday++) {
          if (!training.contains(weekday)) {
            expect(plan.dayOf(weekday), isA<ActiveRestDay>());
          }
        }
      }
    }
    const three = TrainingPlan(
      place: TrainingPlace.home,
      days: 3,
      experience: null,
    );
    final monday = three.dayOf(DateTime.monday) as TrainingDay;
    expect((monday.number, monday.of), (1, 3));
    expect(three.dayOf(DateTime.tuesday), isA<ActiveRestDay>());
  });

  test('each place gets its own exercises, never the same one twice', () {
    const gymOnly = {
      'leg_press',
      'back_squat',
      'lat_pulldown',
      'cable_row',
      'machine_chest_press',
      'triceps_pushdown',
      'leg_curl',
    };
    for (final place in TrainingPlace.values) {
      for (final experience in [...Experience.values, null]) {
        for (var days = 3; days <= 6; days++) {
          final plan = TrainingPlan(
            place: place,
            days: days,
            experience: experience,
          );
          for (var weekday = 1; weekday <= 6; weekday++) {
            final day = plan.dayOf(weekday);
            if (day is! TrainingDay) continue;
            final ids = [for (final e in day.workout.exercises) e.exercise.id];
            expect(ids.toSet(), hasLength(ids.length), reason: '$ids');
            expect(ids.length, greaterThanOrEqualTo(4), reason: '$place');
            if (place == TrainingPlace.home) {
              expect(
                day.workout.exercises.any((e) => e.exercise.weighted),
                isFalse,
                reason: 'home is without equipment: $ids',
              );
            }
            if (place != TrainingPlace.gym) {
              expect(ids.toSet().intersection(gymOnly), isEmpty);
            }
          }
        }
      }
    }
  });

  test('people new to training start easier, with fewer sets', () {
    PlannedWorkout fullBody(Experience? experience) => TrainingPlan(
      place: TrainingPlace.home,
      days: 3,
      experience: experience,
    ).workout('full_a');

    final easy = fullBody(Experience.beginner);
    expect(
      easy.exercises.map((e) => e.exercise.id),
      contains('incline_pushup'),
    );
    expect(easy.exercises.first.sets, 3);
    expect(easy.exercises.last.sets, 2);

    final hard = fullBody(Experience.advanced);
    expect(hard.exercises.map((e) => e.exercise.id), contains('pushup'));
    expect(hard.exercises.first.sets, 4);
    expect(hard.minutes, greaterThan(easy.minutes));
    expect(suggestedDays(Experience.beginner), 3);
    expect(suggestedDays(Experience.advanced), 5);
  });

  test('targets read plainly', () {
    final workout = const TrainingPlan(
      place: TrainingPlace.dumbbells,
      days: 4,
      experience: Experience.intermediate,
    ).workout('lower_a');
    final targets = {
      for (final e in workout.exercises) e.exercise.id: e.target,
    };
    expect(targets['goblet_squat'], '3 × 8-12');
    expect(targets['db_split_squat'], '3 × 8-12 each side');
    expect(targets['plank'], '3 × 30 s');
  });
}
