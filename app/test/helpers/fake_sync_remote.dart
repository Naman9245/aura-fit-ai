import 'package:aurafit/data/sync/sync_remote.dart';

/// One account's copy in memory, keeping the server's rules
/// (supabase/migrations, checked by supabase/tests/sync_test.sql):
///
/// * every write takes the next change number;
/// * an edit no newer than the row's is dropped, and comes back refused;
/// * only one active goal, and one weigh-in a day, checked row by row as a
///   batch is written, so a batch that breaks it is refused whole;
/// * the profile is keyed by the account, so it has no id.
class FakeSyncRemote implements SyncRemote {
  final _tables = <String, Map<String, Map<String, Object?>>>{};
  var _seq = 0;

  /// While true, every call fails as if offline.
  bool offline = false;

  /// Rows the server's checks refuse, as a broken phone might send them. A
  /// batch holding one is refused whole, like a failed statement.
  bool Function(String table, Map<String, Object?> row)? refuse;

  /// Runs before each push is written, as another phone that syncs in the
  /// moment between this phone's fetch and send would.
  void Function(String table)? beforePush;

  /// When true, the next push is written but its reply never reaches the
  /// phone, as when the network drops just then.
  bool loseNextReply = false;

  /// Every row sent from the phone, by table, in order.
  final sent = <String, List<Map<String, Object?>>>{};

  /// How many pushes reached the server.
  var pushes = 0;

  /// The copy's rows of [table], by id, or 'me' for the profile.
  Map<String, Map<String, Object?>> rows(String table) =>
      _tables[table] ?? const {};

  /// Writes [row] as another phone would, by the same rules.
  void put(String table, Map<String, Object?> row) {
    final copy = {...rows(table)};
    _keep(copy, table, row);
    if (_breaksOnlyOne(table, copy)) {
      throw StateError('Another phone could not have written that $table row');
    }
    _tables[table] = copy;
  }

  @override
  Future<List<Map<String, Object?>>> push(
    String table,
    List<Map<String, Object?>> rows,
  ) async {
    if (offline) throw const SyncException(SyncFailure.offline);
    beforePush?.call(table);
    pushes++;
    (sent[table] ??= []).addAll(rows);
    final refuse = this.refuse;
    if (refuse != null && rows.any((row) => refuse(table, row))) {
      throw const SyncException(SyncFailure.badRow, '23514');
    }
    final copy = {...this.rows(table)};
    final refused = <Map<String, Object?>>[];
    for (final row in rows) {
      if (!_keep(copy, table, row)) refused.add({...copy[_keyOf(table, row)]!});
      if (_breaksOnlyOne(table, copy)) {
        throw const SyncException(SyncFailure.clash, '23505');
      }
    }
    _tables[table] = copy;
    if (loseNextReply) {
      loseNextReply = false;
      throw const SyncException(SyncFailure.offline, 'reply lost');
    }
    return refused;
  }

  @override
  Future<List<Map<String, Object?>>> pull(
    String table, {
    required int after,
    required int limit,
  }) async {
    if (offline) throw const SyncException(SyncFailure.offline);
    final newer = [
      for (final row in rows(table).values)
        if ((row['seq']! as int) > after) row,
    ]..sort((a, b) => (a['seq']! as int).compareTo(b['seq']! as int));
    return newer.take(limit).toList();
  }

  static String _keyOf(String table, Map<String, Object?> row) {
    if (table == 'profiles') {
      if (row.containsKey('id')) {
        throw StateError('A profile is keyed by the account, not an id');
      }
      return 'me';
    }
    return row['id']! as String;
  }

  /// Keeps [row] in [copy] unless the copy's edit is as new. Returns
  /// whether it did.
  bool _keep(
    Map<String, Map<String, Object?>> copy,
    String table,
    Map<String, Object?> row,
  ) {
    final key = _keyOf(table, row);
    final old = copy[key];
    if (old != null &&
        !DateTime.parse(row['updated_at']! as String)
            .isAfter(DateTime.parse(old['updated_at']! as String))) {
      return false;
    }
    copy[key] = {...row, 'seq': ++_seq};
    return true;
  }

  /// The unique indexes goals_one_active and weight_logs_one_a_day.
  static bool _breaksOnlyOne(
    String table,
    Map<String, Map<String, Object?>> rows,
  ) {
    bool live(Map<String, Object?> row) =>
        row['deleted_at'] == null &&
        (table != 'goals' || row['ended_at'] == null);
    final alive = rows.values.where(live).toList();
    return switch (table) {
      'goals' => alive.length > 1,
      'weight_logs' =>
        {for (final row in alive) row['day']}.length < alive.length,
      _ => false,
    };
  }
}
