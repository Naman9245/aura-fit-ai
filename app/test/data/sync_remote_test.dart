import 'dart:convert';
import 'dart:io';

import 'package:aurafit/data/sync/sync_remote.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late _Server server;
  late SupabaseClient client;
  late SupabaseSyncRemote remote;

  setUp(() async {
    server = await _Server.start();
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'test-key');
    remote = SupabaseSyncRemote(() async => client);
  });
  tearDown(() async {
    await client.dispose();
    await server.close();
  });

  const id = '019a8c3e-6a00-7000-8000-00000000d001';
  Map<String, Object?> weighIn(double kg, String updatedAt) => {
    'id': id,
    'day': '2026-11-22',
    'weight_kg': kg,
    'created_at': '2026-11-22T04:00:00.000Z',
    'updated_at': updatedAt,
    'deleted_at': null,
  };

  test('rows are matched by account and id, and the account is the '
      "server's to fill in", () async {
    server.account = 'account-1';
    expect(
      await remote.push('weight_logs', [
        weighIn(50, '2026-11-22T04:00:00.000Z'),
      ]),
      isEmpty,
    );
    server.account = 'account-2';
    expect(
      await remote.push('weight_logs', [
        weighIn(50, '2026-11-22T04:00:00.000Z'),
      ]),
      isEmpty,
    );

    expect(
      server.rows('weight_logs').keys,
      unorderedEquals(['account-1/$id', 'account-2/$id']),
    );
    final upsert = server.requests.last;
    expect(upsert.uri.queryParameters['on_conflict'], 'user_id,id');
    expect(
      upsert.uri.queryParameters['columns'],
      allOf(startsWith('"id",'), isNot(contains('user_id'))),
    );
    expect(upsert.headers.value('prefer'), contains('missing=default'));
  });

  test('an edit the copy has a newer one of comes back as the copy has '
      'it', () async {
    server.account = 'account-1';
    await remote.push('weight_logs', [weighIn(52, '2026-11-22T06:00:00.000Z')]);

    final refused = await remote.push('weight_logs', [
      weighIn(51, '2026-11-22T05:00:00.000Z'),
    ]);

    expect(refused.single['weight_kg'], 52);
    expect(server.requests.last.uri.queryParameters['id'], 'in.("$id")');
  });

  test('the profile is one per account, keyed by the account', () async {
    server.account = 'account-1';
    Map<String, Object?> profile(double cm, String updatedAt) => {
      'birth_date': '1996-05-10',
      'height_cm': cm,
      'created_at': '2026-11-22T04:00:00.000Z',
      'updated_at': updatedAt,
      'deleted_at': null,
    };
    expect(
      await remote.push('profiles', [profile(155, '2026-11-22T06:00:00.000Z')]),
      isEmpty,
    );
    expect(server.requests.last.uri.queryParameters['on_conflict'], 'user_id');
    expect(server.rows('profiles').keys, ['account-1/account-1']);

    final refused = await remote.push('profiles', [
      profile(158, '2026-11-22T05:00:00.000Z'),
    ]);
    expect(refused.single['height_cm'], 155);
  });

  test("the server's error codes say what kind of failure it was", () async {
    server.account = 'account-1';
    server.failWith = (409, '23505');
    await expectLater(
      remote.push('goals', [weighIn(50, '2026-11-22T04:00:00.000Z')]),
      throwsA(
        isA<SyncException>()
            .having((e) => e.failure, 'failure', SyncFailure.clash)
            .having((e) => e.detail, 'detail', '23505'),
      ),
    );
    server.failWith = (400, '23514');
    await expectLater(
      remote.push('goals', [weighIn(50, '2026-11-22T04:00:00.000Z')]),
      throwsA(
        isA<SyncException>().having(
          (e) => e.failure,
          'failure',
          SyncFailure.badRow,
        ),
      ),
    );
    expect(SupabaseSyncRemote.failureOf('22003'), SyncFailure.badRow);
    expect(SupabaseSyncRemote.failureOf('23503'), SyncFailure.badRow);
    expect(SupabaseSyncRemote.failureOf('42501'), SyncFailure.failed);
  });

  test('no server at all counts as offline', () async {
    await server.close();
    await expectLater(
      remote.pull('goals', after: 0, limit: 10),
      throwsA(
        isA<SyncException>().having(
          (e) => e.failure,
          'failure',
          SyncFailure.offline,
        ),
      ),
    );
  });
}

/// Just enough of the server's tables: rows keyed by the upsert's conflict
/// columns, each account's own, the account filled in by default, and an
/// edit no newer than the row's dropped.
class _Server {
  _Server._(this._http) {
    _http.listen(_handle);
  }

  static Future<_Server> start() async =>
      _Server._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer _http;
  final _tables = <String, Map<String, Map<String, Object?>>>{};

  /// Who the requests are signed in as.
  String account = '';

  /// When set, every write fails with this status and Postgres code.
  (int, String)? failWith;

  /// Every request so far, oldest first.
  final requests = <HttpRequest>[];

  int get port => _http.port;

  Future<void> close() => _http.close(force: true);

  /// [table]'s rows, by "account/key".
  Map<String, Map<String, Object?>> rows(String table) =>
      _tables[table] ?? const {};

  Future<void> _handle(HttpRequest request) async {
    requests.add(request);
    final table = request.uri.pathSegments.last;
    final query = request.uri.queryParameters;
    final rows = _tables.putIfAbsent(table, () => {});
    final key = table == 'profiles' ? 'user_id' : 'id';
    Object? body;
    var status = HttpStatus.ok;
    final fail = failWith;
    if (request.method == 'POST' && fail != null) {
      status = fail.$1;
      body = {'code': fail.$2, 'message': 'refused', 'details': null};
    } else if (request.method == 'POST') {
      final sent = jsonDecode(await utf8.decoder.bind(request).join()) as List;
      final conflict = query['on_conflict']!.split(',');
      final kept = <Map<String, Object?>>[];
      for (final row in sent.cast<Map<String, Object?>>()) {
        final full = {'user_id': account, ...row};
        final old = rows.values
            .where((r) => conflict.every((c) => r[c] == full[c]))
            .firstOrNull;
        if (old != null &&
            !DateTime.parse(full['updated_at']! as String)
                .isAfter(DateTime.parse(old['updated_at']! as String))) {
          continue;
        }
        rows['$account/${full[key]}'] = full;
        kept.add({key: full[key]});
      }
      status = HttpStatus.created;
      body = kept;
    } else {
      final wanted = query['id']
          ?.replaceFirst('in.(', '')
          .replaceFirst(RegExp(r'\)$'), '')
          .split(',')
          .map((value) => value.replaceAll('"', ''))
          .toSet();
      body = [
        for (final row in rows.values)
          if (row['user_id'] == account &&
              (wanted == null || wanted.contains(row['id'])))
            row,
      ];
    }
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await request.response.close();
  }
}
