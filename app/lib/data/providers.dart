import 'package:aurafit/data/account_data.dart';
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

final accountDataProvider = Provider<AccountData>(
  (ref) => AccountData(ref.watch(appDatabaseProvider)),
);

/// The account this phone's data belongs to, once it has synced; it stays
/// known while signed out, until signing out takes the data off the phone.
final phoneOwnerProvider = StreamProvider<SyncAccountRow?>(
  (ref) => ref.watch(accountDataProvider).watchOwner(),
);

/// The active goal with the working behind it, kept up to date.
final explainedGoalProvider = StreamProvider<ExplainedGoal?>(
  (ref) => ref.watch(profileRepositoryProvider).watchExplainedGoal(),
);
