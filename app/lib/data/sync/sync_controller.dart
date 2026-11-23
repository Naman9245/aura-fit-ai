import 'dart:async';

import 'package:aurafit/core/config.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/data/sync/sync_engine.dart';
import 'package:aurafit/data/sync/sync_remote.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where sync stands, for the account sheet.
enum SyncPhase {
  /// No account: nothing leaves the phone.
  off,
  syncing,
  synced,

  /// No connection. It tries again soon while rows wait, and when the app
  /// comes back.
  offline,

  /// The server refused; it tries again like [offline].
  failed,

  /// The phone holds another account's data, which never goes to this one.
  otherAccount,
}

@immutable
class SyncStatus {
  const SyncStatus(this.phase, {this.lastSynced});

  final SyncPhase phase;

  /// When the last sync finished, while the app has been open.
  final DateTime? lastSynced;
}

/// The signed-in account's copy; null in a build without AURA's server.
final syncRemoteProvider = Provider<SyncRemote?>(
  (ref) => SupabaseConfig.isSet ? SupabaseSyncRemote() : null,
);

/// How long after a change sync waits, so a burst of edits goes up at once.
final syncSettleProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 5),
);

/// How long after a failed sync it tries again, while rows wait. With the
/// 15 s request timeout, a log made offline reaches the account within a
/// minute of the network coming back, while the app is open.
final syncRetryProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 20),
);

/// How many rows wait to be sent.
final syncWaitingProvider = StreamProvider<int>(
  (ref) => SyncEngine.watchWaiting(ref.watch(appDatabaseProvider)),
);

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(
  SyncController.new,
);

/// Keeps the account's copy up to date: right after signing in, when the
/// app opens or comes back, a few seconds after a change, again every 20 s
/// while rows wait after a failed try, and on request. Never with no account.
class SyncController extends Notifier<SyncStatus> {
  Timer? _soon;
  Future<SyncStatus>? _running;
  var _again = false;
  var _stopped = false;
  DateTime? _last;

  /// Rows the server refused, kept out of later syncs while the app runs.
  final _refused = <RefusedRow>{};

  @override
  SyncStatus build() {
    final account = ref.watch(accountProvider).value;
    final remote = ref.watch(syncRemoteProvider);
    _stopped = false;
    ref.onDispose(() => _soon?.cancel());
    if (account == null || remote == null) {
      return const SyncStatus(SyncPhase.off);
    }

    final waiting = SyncEngine.watchWaiting(ref.watch(appDatabaseProvider))
        .listen((count) {
          if (count == 0) {
            _soon?.cancel();
          } else if (_running == null) {
            _soon?.cancel();
            _soon = Timer(ref.read(syncSettleProvider), syncNow);
          }
        });
    ref.onDispose(waiting.cancel);
    // Just signed in, or just opened: sync now.
    scheduleMicrotask(syncNow);
    return SyncStatus(SyncPhase.syncing, lastSynced: _last);
  }

  /// Syncs now, or once more after the sync under way. Completes when it's
  /// done, with how it went.
  ///
  /// Right after signing in, pass the account [as]: the new sign-in takes a
  /// moment to reach [accountProvider].
  Future<SyncStatus> syncNow({Account? as}) {
    if (!ref.mounted || _stopped) return Future.value(_stateOrOff);
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _run(as).whenComplete(() => _running = null);
  }

  /// Waits for any sync under way, and starts no more until the account
  /// changes: signing out takes the data off the phone next.
  Future<void> stop() async {
    _stopped = true;
    _soon?.cancel();
    await _running;
  }

  SyncStatus get _stateOrOff =>
      ref.mounted ? state : const SyncStatus(SyncPhase.off);

  Future<SyncStatus> _run(Account? as) async {
    _soon?.cancel();
    final account = as ?? ref.read(accountProvider).value;
    final remote = ref.read(syncRemoteProvider);
    if (account == null || remote == null) {
      return const SyncStatus(SyncPhase.off);
    }
    state = SyncStatus(SyncPhase.syncing, lastSynced: _last);
    final db = ref.read(appDatabaseProvider);
    var phase = SyncPhase.synced;
    try {
      do {
        _again = false;
        await SyncEngine(
          db,
          remote,
          refused: _refused,
        ).sync(account.id, email: account.email);
      } while (_again && ref.mounted && !_stopped);
      _last = clock.now();
    } on SyncException catch (error) {
      phase = switch (error.failure) {
        SyncFailure.offline => SyncPhase.offline,
        SyncFailure.otherAccount => SyncPhase.otherAccount,
        _ => SyncPhase.failed,
      };
      debugPrint('AURA sync: ${phase.name} (${error.detail})');
    } on Exception catch (error) {
      phase = SyncPhase.failed;
      debugPrint('AURA sync: failed (${error.runtimeType})');
    }
    final status = SyncStatus(phase, lastSynced: _last);
    if (!ref.mounted) return status;
    state = status;
    if (phase == SyncPhase.offline || phase == SyncPhase.failed) {
      final waiting = await SyncEngine.watchWaiting(db).first;
      if (waiting > 0 && ref.mounted && !_stopped) {
        _soon?.cancel();
        _soon = Timer(ref.read(syncRetryProvider), syncNow);
      }
    }
    return status;
  }
}
