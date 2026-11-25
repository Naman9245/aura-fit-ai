import 'dart:math' as math;

import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/sync/sync_remote.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

/// A row the server refused, kept out of later sends until it changes here:
/// its table, its key and the stamp of the edit that was refused.
typedef RefusedRow = (String table, Object? key, Object? updatedAt);

/// Keeps this phone's data and the signed-in account's copy the same. It
/// fetches what changed in the copy since last time, then sends what changed
/// here. The newer edit of a row wins on both sides, an edit the copy refuses
/// gives way to the copy's own, and deletes travel as marks, so every phone
/// ends up with the same rows. Ported from Penny's.
///
/// It fetches first because the server allows one active goal and one
/// weigh-in a day per account. A phone that sent its own first, while another
/// phone's row stood in the way, would have its whole batch refused.
class SyncEngine {
  SyncEngine(
    this._db,
    this._remote, {
    DateTime Function()? clock,
    Set<RefusedRow>? refused,
    void Function(String message)? log,
  }) : _clock = clock ?? DateTime.now,
       _refused = refused ?? <RefusedRow>{},
       _log = log ?? debugPrint;

  final AppDatabase _db;
  final SyncRemote _remote;
  final DateTime Function() _clock;

  /// Rows the server refused, by the caller's reckoning across syncs.
  final Set<RefusedRow> _refused;
  final void Function(String message) _log;

  /// Rows per request, each way.
  static const batch = 500;

  /// One full sync with [account]'s copy. Throws [SyncException]; whatever
  /// wasn't sent stays marked, so the next sync carries on.
  Future<void> sync(String account, {String? email}) async {
    await _bindTo(account, email);
    for (var attempt = 0; ; attempt++) {
      try {
        for (final kind in _kinds) {
          await _pull(kind);
        }
        var settled = false;
        for (final kind in _kinds) {
          if (await _push(kind)) settled = true;
        }
        // Taking a row the copy refused retired a clashing one here; send
        // that straight back.
        if (settled) {
          for (final kind in _kinds) {
            await _push(kind);
          }
        }
        return;
      } on SyncException catch (error) {
        // Another phone's row arrived between the fetch and the send: fetch
        // again, settle it here, and send once more.
        if (error.failure != SyncFailure.clash || attempt > 0) rethrow;
      }
    }
  }

  /// How many rows wait to be sent, as it changes.
  static Stream<int> watchWaiting(AppDatabase db) {
    final counts = [
      for (final kind in _kinds)
        '(SELECT COUNT(*) FROM ${kind.table} WHERE dirty = 1)',
    ];
    return db
        .customSelect(
          'SELECT ${counts.join(' + ')} AS waiting',
          readsFrom: {for (final kind in _kinds) _tableIn(db, kind)},
        )
        .watchSingle()
        .map((row) => row.read<int>('waiting'));
  }

  /// Ties this phone's data to [account] on its first sync: everything here
  /// goes up, and the copy comes down from its start. Data that belongs to
  /// another account never goes to this one.
  Future<void> _bindTo(String account, String? email) async {
    final bound = await _db.select(_db.syncAccount).getSingleOrNull();
    if (bound != null) {
      if (bound.accountId != account) {
        throw const SyncException(SyncFailure.otherAccount);
      }
      if (email != null && bound.email != email) {
        await _db
            .update(_db.syncAccount)
            .write(SyncAccountCompanion(email: Value(email)));
      }
      return;
    }
    await _db.transaction(() async {
      await (_db.delete(
            _db.syncCursors,
          )..where((c) => c.kind.isIn([for (final kind in _kinds) kind.table])))
          .go();
      for (final kind in _kinds) {
        await _db.customUpdate(
          'UPDATE ${kind.table} SET dirty = 1 WHERE dirty = 0',
          updates: {_tableOf(kind)},
        );
      }
      await _db
          .into(_db.syncAccount)
          .insert(
            SyncAccountCompanion.insert(
              accountId: account,
              email: Value(email),
              boundAt: _clock(),
            ),
          );
    });
  }

  /// Sends what changed here, a batch at a time, retired rows before live
  /// ones, then marks it sent unless it changed again meanwhile. Where the
  /// copy refused an edit, its own being as new, this phone takes the
  /// copy's. Returns whether taking one retired a clashing row here.
  Future<bool> _push(_Kind kind) async {
    var settled = false;
    for (var round = 0; round < 200; round++) {
      final rows = await _waiting(kind);
      if (rows.isEmpty) return settled;
      final sent = <Map<String, Object?>>[];
      final refused = <Map<String, Object?>>[];
      try {
        refused.addAll(
          await _remote.push(kind.table, [
            for (final row in rows) kind.toRemote(row),
          ]),
        );
        sent.addAll(rows);
      } on SyncException catch (error) {
        if (error.failure != SyncFailure.badRow) rethrow;
        // One of them breaks one of the server's rules. Send them one at a
        // time, so the rest still go up.
        for (final row in rows) {
          try {
            refused.addAll(
              await _remote.push(kind.table, [kind.toRemote(row)]),
            );
            sent.add(row);
          } on SyncException catch (error) {
            if (error.failure != SyncFailure.badRow) rethrow;
            _refused.add((kind.table, row[kind.key], row['updated_at']));
            _log(
              'AURA sync: the server refused a ${kind.table} row '
              '(${error.detail})',
            );
          }
        }
      }
      await _markSent(kind, sent);
      final stamps = {for (final row in sent) row[kind.key]: row['updated_at']};
      for (final theirs in refused) {
        final key = kind.toLocal(theirs)[kind.key];
        if (await _apply(kind, theirs, replacing: stamps[key])) settled = true;
      }
      if (rows.length < batch) return settled;
    }
    return settled;
  }

  /// The next rows of [kind] to send: retired ones first, so a row that
  /// takes its place never meets it on the server, and none the server
  /// refused unless they've changed since.
  Future<List<Map<String, Object?>>> _waiting(_Kind kind) async {
    final skip = [
      for (final row in _refused)
        if (row.$1 == kind.table) row,
    ];
    final notRefused = skip.isEmpty
        ? ''
        : ' AND (${kind.key}, updated_at) NOT IN '
              '(VALUES ${List.filled(skip.length, '(?, ?)').join(', ')})';
    final rows = await _db
        .customSelect(
          'SELECT ${kind.columns.join(', ')} FROM ${kind.table} '
          'WHERE dirty = 1$notRefused '
          'ORDER BY ${kind.live}, updated_at LIMIT $batch',
          variables: [
            for (final row in skip) ...[
              Variable<Object>(row.$2),
              Variable<Object>(row.$3),
            ],
          ],
          readsFrom: {_tableOf(kind)},
        )
        .get();
    return [for (final row in rows) row.data];
  }

  /// One statement for the batch: a row edited again meanwhile has a new
  /// updated_at, so it stays marked.
  Future<void> _markSent(_Kind kind, List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return;
    final pairs = List.filled(rows.length, '(?, ?)').join(', ');
    await _db.customUpdate(
      'UPDATE ${kind.table} SET dirty = 0 '
      'WHERE (${kind.key}, updated_at) IN (VALUES $pairs)',
      variables: [
        for (final row in rows) ...[
          Variable<Object>(row[kind.key]),
          Variable<Object>(row['updated_at']),
        ],
      ],
      updates: {_tableOf(kind)},
    );
  }

  /// Fetches what changed in the copy since last time, oldest first, and
  /// keeps how far it got.
  Future<void> _pull(_Kind kind) async {
    var after =
        (await (_db.select(
          _db.syncCursors,
        )..where((c) => c.kind.equals(kind.table))).getSingleOrNull())?.seq ??
        0;
    for (var round = 0; round < 1000; round++) {
      final rows = await _remote.pull(kind.table, after: after, limit: batch);
      await _db.transaction(() async {
        for (final row in rows) {
          await _apply(kind, row);
        }
        if (rows.isNotEmpty) after = (rows.last['seq']! as num).toInt();
        await _db
            .into(_db.syncCursors)
            .insertOnConflictUpdate(
              SyncCursorsCompanion.insert(kind: kind.table, seq: after),
            );
      });
      if (rows.length < batch) break;
    }
  }

  /// Writes one row from the copy, unless this phone's is as new. With
  /// [replacing], the stamp of an edit the copy refused, it writes the
  /// copy's row over that edit instead, unless the row changed here again
  /// since it was sent.
  ///
  /// Where only one live row may be, like the active goal or a day's
  /// weigh-in, the newer of the two stays live and the other is retired
  /// here, marked to send. Returns whether that happened.
  Future<bool> _apply(
    _Kind kind,
    Map<String, Object?> remote, {
    Object? replacing,
  }) async {
    final table = _tableOf(kind);
    final values = kind.toLocal(remote);
    var dirty = 0;
    var settled = false;
    final unique = kind.unique;
    if (unique != null && kind.isLive(values)) {
      final sameKey = [for (final column in unique) ' AND $column = ?'];
      final clash = await _db
          .customSelect(
            'SELECT ${kind.key} AS key, updated_at FROM ${kind.table} '
            'WHERE ${kind.live} AND ${kind.key} <> ?${sameKey.join()}',
            variables: [
              Variable<Object>(values[kind.key]),
              for (final column in unique) Variable<Object>(values[column]),
            ],
            readsFrom: {table},
          )
          .getSingleOrNull();
      if (clash != null) {
        settled = true;
        final theirs = (values['updated_at']! as int, '${values[kind.key]}');
        final ours = (clash.read<int>('updated_at'), clash.read<String>('key'));
        // Retired now, but always after the loser's last edit, so the
        // newer-edit-wins rule carries the retirement everywhere.
        int retiredAt((int, String) loser) =>
            math.max(_seconds(_clock()), loser.$1 + 1);
        if (_newer(theirs, ours)) {
          final at = retiredAt(ours);
          await _db.customUpdate(
            'UPDATE ${kind.table} SET ${kind.retireBy} = ?, updated_at = ?, '
            'dirty = 1 WHERE ${kind.key} = ?',
            variables: [Variable(at), Variable(at), Variable(ours.$2)],
            updates: {table},
          );
        } else {
          final at = retiredAt(theirs);
          values[kind.retireBy] = at;
          values['updated_at'] = at;
          dirty = 1;
        }
      }
    }
    final columns = [...kind.columns, 'dirty'];
    // From a fetch, only a newer edit goes in; over a refused edit, the
    // copy's goes in as long as nothing changed here since.
    final newer = 'excluded.updated_at > ${kind.table}.updated_at';
    final assignments = [
      for (final column in columns)
        if (column != kind.key) '$column = excluded.$column',
    ];
    await _db.customInsert(
      'INSERT INTO ${kind.table} (${columns.join(', ')}) '
      'VALUES (${List.filled(columns.length, '?').join(', ')}) '
      'ON CONFLICT(${kind.key}) DO UPDATE SET ${assignments.join(', ')} '
      'WHERE ${replacing == null ? newer : '${kind.table}.updated_at = ?'}',
      variables: [
        for (final column in kind.columns) Variable<Object>(values[column]),
        Variable(dirty),
        if (replacing != null) Variable<Object>(replacing),
      ],
      updates: {table},
    );
    return settled;
  }

  TableInfo<Table, Object?> _tableOf(_Kind kind) => _tableIn(_db, kind);
}

TableInfo<Table, Object?> _tableIn(AppDatabase db, _Kind kind) =>
    db.allTables.firstWhere((table) => table.actualTableName == kind.table);

/// Whether ([updatedAt], key) [a] is newer than [b]; the key breaks a tie,
/// so two phones settle the same way.
bool _newer((int, String) a, (int, String) b) =>
    a.$1 > b.$1 || (a.$1 == b.$1 && a.$2.compareTo(b.$2) > 0);

/// Drift keeps dates as whole seconds since the epoch.
int _seconds(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

/// One synced table: its columns, named the same on both sides, which of
/// them hold dates, and what only one live row may share.
class _Kind {
  const _Kind(
    this.table, {
    required this.columns,
    this.dates = const {'created_at', 'updated_at', 'deleted_at'},
    this.unique,
    this.retireBy = 'deleted_at',
    this.perAccount = false,
  });

  /// Its name, the same on the phone and the server.
  final String table;

  /// The columns that travel, with the phone's key first. Anything else
  /// stays on the phone.
  final List<String> columns;
  final Set<String> dates;

  /// What only one live row may share, like a weigh-in's day; empty when
  /// only one live row may exist at all, like the active goal; null when
  /// any number may.
  final List<String>? unique;

  /// The column that retires the loser of a clash: deleted_at, or ended_at
  /// for a goal, which then stays as history.
  final String retireBy;

  /// One row per account: the phone keys it by id 1 and the server by the
  /// account, which it fills in itself, so the id never travels.
  final bool perAccount;

  /// The phone's key: the row's id.
  String get key => 'id';

  /// The SQL for a live row: not deleted, and for a goal not ended.
  String get live => retireBy == 'deleted_at'
      ? 'deleted_at IS NULL'
      : '(deleted_at IS NULL AND $retireBy IS NULL)';

  bool isLive(Map<String, Object?> values) =>
      values['deleted_at'] == null && values[retireBy] == null;

  Map<String, Object?> toRemote(Map<String, Object?> local) => {
    for (final column in columns)
      if (!(perAccount && column == key))
        column: switch (local[column]) {
          final int seconds when dates.contains(column) =>
            DateTime.fromMillisecondsSinceEpoch(
              seconds * 1000,
              isUtc: true,
            ).toIso8601String(),
          final value => value,
        },
  };

  Map<String, Object?> toLocal(Map<String, Object?> remote) => {
    for (final column in columns)
      column: perAccount && column == key
          ? 1
          : switch (remote[column]) {
              final String text when dates.contains(column) => _seconds(
                DateTime.parse(text),
              ),
              final value => value,
            },
  };
}

const _stamps = {'created_at', 'updated_at', 'deleted_at'};

/// Every synced table, in the order they travel.
const _kinds = [
  _Kind(
    'profiles',
    perAccount: true,
    columns: [
      'id',
      'birth_date',
      'sex',
      'height_cm',
      'activity_level',
      'diet_type',
      'training_place',
      'experience',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
  ),
  _Kind(
    'goals',
    columns: [
      'id',
      'goal_type',
      'target_weight_kg',
      'basis_weight_kg',
      'calories_kcal',
      'protein_g',
      'carbs_g',
      'fat_g',
      'water_ml',
      'steps',
      'formula_version',
      'started_at',
      'ended_at',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    dates: {..._stamps, 'started_at', 'ended_at'},
    unique: [],
    retireBy: 'ended_at',
  ),
  _Kind(
    'weight_logs',
    columns: [
      'id',
      'day',
      'weight_kg',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    unique: ['day'],
  ),
  _Kind(
    'meal_entries',
    columns: [
      'id',
      'food_id',
      'name',
      'meal',
      'day',
      'portion_unit',
      'portion_count',
      'oil_level',
      'grams',
      'kcal',
      'protein_g',
      'carbs_g',
      'fat_g',
      'eaten_at',
      'source',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    dates: {..._stamps, 'eaten_at'},
  ),
  _Kind(
    'saved_meals',
    columns: ['id', 'name', 'created_at', 'updated_at', 'deleted_at'],
  ),
  _Kind(
    'saved_meal_items',
    columns: [
      'id',
      'saved_meal_id',
      'food_id',
      'name',
      'portion_unit',
      'portion_count',
      'oil_level',
      'grams',
      'kcal',
      'protein_g',
      'carbs_g',
      'fat_g',
      'sort_order',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
  ),
  _Kind(
    'health_samples',
    columns: [
      'id',
      'metric',
      'day',
      'value',
      'measured_at',
      'source',
      'created_at',
      'updated_at',
      'deleted_at',
    ],
    dates: {..._stamps, 'measured_at'},
  ),
];
