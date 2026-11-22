import 'package:aurafit/data/db/app_database.dart';
import 'package:drift/drift.dart';

/// An account's data on this phone, as one thing: whose it is, and taking
/// it all off the phone.
class AccountData {
  AccountData(this._db);

  final AppDatabase _db;

  /// The account the phone's data belongs to, once it has synced.
  Future<SyncAccountRow?> owner() =>
      _db.select(_db.syncAccount).getSingleOrNull();

  Stream<SyncAccountRow?> watchOwner() =>
      _db.select(_db.syncAccount).watchSingleOrNull();

  /// Removes everything of the account's from this phone: its rows, how far
  /// sync got, and whose they were. The account's copy keeps them all.
  Future<void> removeAll() => _db.transaction(() async {
    for (final table in <TableInfo<Table, Object?>>[
      _db.profiles,
      _db.goals,
      _db.weightLogs,
      _db.mealEntries,
      _db.healthSamples,
      _db.syncCursors,
      _db.syncAccount,
    ]) {
      await _db.delete(table).go();
    }
  });
}
