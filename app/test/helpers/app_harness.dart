import 'package:aurafit/app.dart';
import 'package:aurafit/core/error_reporter.dart';
import 'package:aurafit/core/links.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/data/sync/sync_controller.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_account_service.dart';
import 'fake_sync_remote.dart';

/// The day the widget tests happen on, so ages come out the same whenever
/// they run. Tests run inside `withClock(Clock.fixed(testNow), ...)`.
final testNow = DateTime(2026, 11, 22, 9);

/// Starts the app on a phone-sized screen at [startAt], with an in-memory
/// database holding what [seed] saves. With [accounts] and [remote], it
/// signs in and syncs with those fakes; without them, it's a build with no
/// server, which never syncs.
///
/// Seed here rather than after start-up: writing from outside the test's
/// fake time while the app's live queries are open deadlocks drift.
Future<AppDatabase> pumpAura(
  WidgetTester tester, {
  required String startAt,
  Object? startExtra,
  Future<void> Function(ProfileRepository repo)? seed,
  Future<void> Function(AppDatabase db)? seedDb,
  FakeAccountService? accounts,
  FakeSyncRemote? remote,
  CrashReportSwitch? crashReports,
  Future<void> Function(Uri)? openLink,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  // The test unmounts the app before tear-downs run, so nothing is still
  // reading when this closes.
  addTearDown(db.close);
  if (seed != null) await tester.runAsync(() => seed(ProfileRepository(db)));
  if (seedDb != null) await tester.runAsync(() => seedDb(db));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (accounts != null)
          accountServiceProvider.overrideWithValue(accounts),
        if (remote != null) syncRemoteProvider.overrideWithValue(remote),
        if (crashReports != null)
          crashReportsProvider.overrideWithValue(crashReports),
        if (openLink != null) openLinkProvider.overrideWithValue(openLink),
      ],
      child: AuraApp(startAt: startAt, startExtra: startExtra),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}
