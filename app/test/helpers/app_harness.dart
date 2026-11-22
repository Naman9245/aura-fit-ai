import 'package:aurafit/app.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The day the widget tests happen on, so ages come out the same whenever
/// they run. Tests run inside `withClock(Clock.fixed(testNow), ...)`.
final testNow = DateTime(2026, 11, 22, 9);

/// Starts the app on a phone-sized screen at [startAt], with an in-memory
/// database holding what [seed] saves.
///
/// Seed here rather than after start-up: writing from outside the test's
/// fake time while the app's live queries are open deadlocks drift.
Future<AppDatabase> pumpAura(
  WidgetTester tester, {
  required String startAt,
  Future<void> Function(ProfileRepository repo)? seed,
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
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: AuraApp(startAt: startAt),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}
