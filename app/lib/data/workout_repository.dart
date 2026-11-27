import 'dart:convert';

import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/db/converters.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// One set as done: reps (or seconds held), the weight, and whether it was
/// finished.
@immutable
class LoggedSet {
  const LoggedSet({
    required this.exercise,
    this.reps,
    this.kg,
    this.seconds,
    this.done = false,
  });

  factory LoggedSet.fromJson(Map<String, Object?> json) => LoggedSet(
    exercise: json['exercise']! as String,
    reps: (json['reps'] as num?)?.toInt(),
    kg: (json['kg'] as num?)?.toDouble(),
    seconds: (json['seconds'] as num?)?.toInt(),
    done: json['done'] == true,
  );

  final String exercise;
  final int? reps;
  final double? kg;
  final int? seconds;
  final bool done;

  LoggedSet copyWith({int? reps, double? kg, int? seconds, bool? done}) =>
      LoggedSet(
        exercise: exercise,
        reps: reps ?? this.reps,
        kg: kg ?? this.kg,
        seconds: seconds ?? this.seconds,
        done: done ?? this.done,
      );

  Map<String, Object?> toJson() => {
    'exercise': exercise,
    'reps': reps,
    'kg': kg,
    'seconds': seconds,
    'done': done,
  };
}

/// The sets stored with a session.
List<LoggedSet> setsOf(WorkoutSessionRow row) => [
  for (final item in jsonDecode(row.sets) as List<Object?>)
    LoggedSet.fromJson((item! as Map).cast<String, Object?>()),
];

/// Workouts done, on this phone first and synced like everything else.
class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Saves a workout done on [day]. Returns its id.
  Future<String> saveSession({
    required DateTime day,
    required String workoutKey,
    required String title,
    required List<LoggedSet> sets,
    required DateTime startedAt,
  }) async {
    final now = clock.now();
    final id = _uuid.v7();
    final done = sets.where((s) => s.done).length;
    final minutes = now.difference(startedAt).inMinutes.clamp(0, 600);
    await _db
        .into(_db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: id,
            day: diaryDay(day),
            workoutKey: workoutKey,
            title: title,
            sets: Value(jsonEncode([for (final s in sets) s.toJson()])),
            setsDone: done.clamp(0, 200),
            setsPlanned: sets.length.clamp(0, 200),
            durationMin: Value(minutes),
            startedAt: startedAt,
            finishedAt: Value(now),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Takes a workout off the log, with Undo.
  Future<UndoAction> deleteSession(WorkoutSessionRow row) async {
    Future<void> mark(DateTime? deletedAt) async {
      final at = clock.now();
      await (_db.update(
        _db.workoutSessions,
      )..where((w) => w.id.equals(row.id))).write(
        WorkoutSessionsCompanion(
          deletedAt: Value(deletedAt),
          updatedAt: Value(at),
          dirty: const Value(true),
        ),
      );
    }

    await mark(clock.now());
    return UndoAction(
      message: 'Removed ${row.title.toLowerCase()}',
      undo: () => mark(null),
    );
  }

  /// Workouts on the days from [from] to [to], both included.
  Stream<List<WorkoutSessionRow>> watchBetween(DateTime from, DateTime to) {
    const dates = DateConverter();
    return (_db.select(_db.workoutSessions)
          ..where(
            (w) =>
                w.deletedAt.isNull() &
                w.day.isBiggerOrEqualValue(dates.toSql(diaryDay(from))) &
                w.day.isSmallerOrEqualValue(dates.toSql(diaryDay(to))),
          )
          ..orderBy([(w) => OrderingTerm.asc(w.startedAt)]))
        .watch();
  }

  /// Every diary day with a workout, for the calendar.
  Stream<Set<DateTime>> watchWorkoutDays() {
    final day = _db.workoutSessions.day;
    final query = _db.selectOnly(_db.workoutSessions, distinct: true)
      ..addColumns([day])
      ..where(_db.workoutSessions.deletedAt.isNull());
    return query.watch().map(
      (rows) => {for (final row in rows) row.readWithConverter(day)!},
    );
  }

  /// The sets of [exercise] from the last workout that had it, to start
  /// the next one from.
  Future<List<LoggedSet>> lastSets(String exercise) async {
    final recent =
        await (_db.select(_db.workoutSessions)
              ..where((w) => w.deletedAt.isNull())
              ..orderBy([(w) => OrderingTerm.desc(w.startedAt)])
              ..limit(30))
            .get();
    for (final row in recent) {
      final sets = [
        for (final s in setsOf(row))
          if (s.exercise == exercise && s.done) s,
      ];
      if (sets.isNotEmpty) return sets;
    }
    return const [];
  }
}
