import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The phone's database. Tests override it with an in-memory one.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(appDatabaseProvider)),
);

/// The active goal with the working behind it, kept up to date.
final explainedGoalProvider = StreamProvider<ExplainedGoal?>(
  (ref) => ref.watch(profileRepositoryProvider).watchExplainedGoal(),
);
