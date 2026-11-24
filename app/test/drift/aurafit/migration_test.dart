// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // Every schema update, with no data: the migrated tables must come out
    // exactly as a fresh install makes them.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // A phone from the Foundation build has a profile, a weigh-in and a goal,
  // none of them sent anywhere yet. Sync's tables arrive empty, and those
  // rows stay exactly as they were, still marked to send.
  test('v1 to v2 keeps what onboarding saved, still to send', () async {
    // 22 Nov 2026, 09:30 IST, in seconds since the epoch.
    const saved = 1795320000;
    const goalId = '019a8c3e-6a00-7000-8000-000000000001';
    const weightId = '019a8c3e-6a00-7000-8000-000000000002';

    final profile = v1.ProfilesData(
      dirty: 1,
      id: 1,
      birthDate: '1996-05-10',
      sex: 'female',
      heightCm: 155,
      activityLevel: 'sedentary',
      dietType: 'veg',
      trainingPlace: null,
      experience: null,
      createdAt: saved,
      updatedAt: saved,
      deletedAt: null,
    );
    final goal = v1.GoalsData(
      dirty: 1,
      id: goalId,
      goalType: 'lose_fat',
      targetWeightKg: null,
      basisWeightKg: 50,
      caloriesKcal: 1200,
      proteinG: 90,
      carbsG: 120,
      fatG: 40,
      waterMl: 1750,
      steps: 8000,
      formulaVersion: 'v1',
      startedAt: saved,
      endedAt: null,
      createdAt: saved,
      updatedAt: saved,
      deletedAt: null,
    );
    final weight = v1.WeightLogsData(
      dirty: 1,
      id: weightId,
      day: '2026-11-22',
      weightKg: 50,
      createdAt: saved,
      updatedAt: saved,
      deletedAt: null,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.profiles, profile);
        batch.insert(oldDb.goals, goal);
        batch.insert(oldDb.weightLogs, weight);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.profiles).get(), [
          v2.ProfilesData.fromJson(profile.toJson()),
        ]);
        expect(await newDb.select(newDb.goals).get(), [
          v2.GoalsData.fromJson(goal.toJson()),
        ]);
        expect(await newDb.select(newDb.weightLogs).get(), [
          v2.WeightLogsData.fromJson(weight.toJson()),
        ]);
        expect(await newDb.select(newDb.syncCursors).get(), isEmpty);
        expect(await newDb.select(newDb.syncAccount).get(), isEmpty);
      },
    );
  });

  // v3 rebuilds the tables with the server's limits. A signed-in phone's
  // rows, all inside those limits, come through the rebuild unchanged.
  test('v2 to v3 keeps every row through the rebuild', () async {
    const saved = 1795320000;
    final profile = v2.ProfilesData(
      dirty: 0,
      id: 1,
      birthDate: '1996-05-10',
      sex: 'female',
      heightCm: 155,
      activityLevel: 'sedentary',
      dietType: null,
      trainingPlace: 'gym',
      experience: 'beginner',
      createdAt: saved,
      updatedAt: saved,
      deletedAt: null,
    );
    final goal = v2.GoalsData(
      dirty: 1,
      id: '019a8c3e-6a00-7000-8000-000000000001',
      goalType: 'lose_fat',
      targetWeightKg: 48,
      basisWeightKg: 50,
      caloriesKcal: 1200,
      proteinG: 90,
      carbsG: 135,
      fatG: 33,
      waterMl: 1750,
      steps: 8000,
      formulaVersion: 'v1',
      startedAt: saved,
      endedAt: null,
      createdAt: saved,
      updatedAt: saved,
      deletedAt: null,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(oldDb.profiles, profile);
        batch.insert(oldDb.goals, goal);
      },
      validateItems: (newDb) async {
        expect(await newDb.select(newDb.profiles).get(), [
          v3.ProfilesData.fromJson(profile.toJson()),
        ]);
        expect(await newDb.select(newDb.goals).get(), [
          v3.GoalsData.fromJson(goal.toJson()),
        ]);
      },
    );
  });
}
