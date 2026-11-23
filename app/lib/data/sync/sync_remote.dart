import 'dart:async';
import 'dart:math' as math;

import 'package:aurafit/data/supabase_start.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The signed-in account's copy of its tables, as rows keyed by the
/// server's column names, with dates as ISO 8601 text.
abstract interface class SyncRemote {
  /// Sends [rows] of [table], written in this order. The copy keeps the
  /// newer edit of each row: returned are the rows it refused, as it has
  /// them, its own edit being as new.
  Future<List<Map<String, Object?>>> push(
    String table,
    List<Map<String, Object?>> rows,
  );

  /// Up to [limit] rows of [table] changed after change number [after],
  /// oldest change first, each with its `seq`.
  Future<List<Map<String, Object?>>> pull(
    String table, {
    required int after,
    required int limit,
  });
}

/// Why a sync stopped.
enum SyncFailure {
  /// No internet, or the server didn't answer in time. It tries again.
  offline,

  /// The copy has another live row where only one may be, like a second
  /// active goal: another phone's arrived after this phone last fetched.
  clash,

  /// The server refused a row's values, like a number past its limit.
  badRow,

  /// This phone's data belongs to another account.
  otherAccount,

  /// The server refused, or something unexpected went wrong.
  failed,
}

class SyncException implements Exception {
  const SyncException(this.failure, [this.detail]);

  final SyncFailure failure;

  /// A Postgres error code or a short reason, never what a row holds.
  final String? detail;

  @override
  String toString() => 'SyncException(${failure.name}, $detail)';
}

/// [SyncRemote] over Supabase's tables, as the signed-in user. Row-level
/// security keeps each account to its own rows, and the server fills in
/// user_id, so the phone never sends it.
class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote([this._connect = startSupabase]);

  final Future<SupabaseClient> Function() _connect;

  /// A sync request that takes longer is treated as no connection, so the
  /// next try comes soon. Reads don't use the client's own retries either:
  /// the sync controller decides when to try again.
  static const _timeout = Duration(seconds: 15);

  /// Rows asked for by id at a time, keeping the address short.
  static const _idsPerFetch = 100;

  @override
  Future<List<Map<String, Object?>>> push(
    String table,
    List<Map<String, Object?>> rows,
  ) => _guard(() async {
    final client = await _connect();
    if (table == 'profiles') {
      // One per account, keyed by the account itself.
      final kept = await client
          .from(table)
          .upsert(rows, onConflict: 'user_id', defaultToNull: false)
          .select('user_id');
      if (kept.isNotEmpty) return const [];
      final theirs = await client.from(table).select().retry(enabled: false);
      return [for (final row in theirs) Map<String, Object?>.of(row)];
    }
    // Ids are made on the phones, so two accounts can hold the same one:
    // the copy keys rows by account and id.
    final kept = await client
        .from(table)
        .upsert(rows, onConflict: 'user_id,id', defaultToNull: false)
        .select('id');
    // The copy's trigger drops an edit no newer than its own, and only the
    // rows it wrote come back.
    final keptIds = {for (final row in kept) row['id']};
    final refused = [
      for (final row in rows)
        if (!keptIds.contains(row['id'])) row['id'],
    ];
    final theirs = <Map<String, Object?>>[];
    for (var i = 0; i < refused.length; i += _idsPerFetch) {
      final some = refused.sublist(
        i,
        math.min(i + _idsPerFetch, refused.length),
      );
      final rows = await client
          .from(table)
          .select()
          .inFilter('id', some)
          .retry(enabled: false);
      theirs.addAll([for (final row in rows) Map<String, Object?>.of(row)]);
    }
    return theirs;
  });

  @override
  Future<List<Map<String, Object?>>> pull(
    String table, {
    required int after,
    required int limit,
  }) => _guard(() async {
    final client = await _connect();
    final rows = await client
        .from(table)
        .select()
        .gt('seq', after)
        .order('seq')
        .limit(limit)
        .retry(enabled: false);
    return [for (final row in rows) Map<String, Object?>.of(row)];
  });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on TimeoutException {
      throw const SyncException(SyncFailure.offline, 'timeout');
    } on PostgrestException catch (error) {
      throw SyncException(failureOf(error.code), error.code);
    } on AuthException catch (error) {
      throw SyncException(SyncFailure.failed, error.code ?? error.statusCode);
    } on Exception catch (error) {
      // Socket and client errors: no connection.
      throw SyncException(SyncFailure.offline, '${error.runtimeType}');
    }
  }

  /// What a Postgres error [code] means for a sync: a clash with another
  /// phone's live row, a row whose values the server won't take, or
  /// anything else.
  static SyncFailure failureOf(String? code) => switch (code) {
    // unique_violation
    '23505' => SyncFailure.clash,
    // Data exceptions (a value too long or out of range) and other
    // integrity rules: a check, a missing food, a null.
    final String code when code.startsWith('22') || code.startsWith('23') =>
      SyncFailure.badRow,
    _ => SyncFailure.failed,
  };
}
