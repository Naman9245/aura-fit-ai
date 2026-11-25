import 'dart:convert';

import 'package:aurafit/core/error_reporter.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/data_export.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

class _CapturedShare implements ShareService {
  List<ExportedFile> last = const [];

  @override
  Future<void> shareFiles(List<ExportedFile> files) async {
    last = files;
  }
}

void main() {
  test('error reporter strips exception messages that could hold PII', () {
    SafeErrorReport? captured;
    debugSetErrorSink((r) => captured = r);
    addTearDown(() => debugSetErrorSink(null));

    reportAuraError(
      const FormatException('secret@example.com / Paneer Tikka'),
      StackTrace.current,
      where: 'meals.parse',
    );

    expect(captured, isNotNull);
    expect(captured!.where, 'meals.parse');
    expect(captured!.errorType, 'FormatException');
  });

  test(
    'DataExporter builds offline JSON and CSV with meals, goals and weights',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final at = DateTime(2026, 11, 22, 13, 0);

      await withClock(Clock.fixed(at), () async {
        await ProfileRepository(db).saveProfile(
          ProfileAnswers(
            goal: GoalType.loseFat,
            birthDate: DateTime(1996, 5, 10),
            sex: Sex.female,
            heightCm: 155,
            weightKg: 50,
            activity: ActivityLevel.sedentary,
            diet: DietType.veg,
          ),
        );
        await db
            .into(db.mealEntries)
            .insert(
              MealEntriesCompanion.insert(
                id: 'meal-1',
                name: 'Moong Dal, Home Style',
                meal: Meal.lunch,
                day: DateTime(2026, 11, 22),
                portionUnit: const Value('katori'),
                portionCount: const Value(1),
                oilLevel: const Value(OilLevel.home),
                grams: 150,
                kcal: 165,
                proteinG: 10,
                carbsG: 22,
                fatG: 4,
                eatenAt: at,
                source: EntrySource.search,
                createdAt: at,
                updatedAt: at,
              ),
            );

        final files = await DataExporter(db).buildExport();
        expect(files.map((f) => f.name), [
          'aurafit-export.json',
          'aurafit-export.csv',
        ]);

        final decoded = jsonDecode(files.first.content) as Map<String, Object?>;
        expect((decoded['profile']! as Map)['diet_type'], 'veg');
        final meals = decoded['meal_entries']! as List<Object?>;
        expect((meals.single! as Map)['portion_unit'], 'katori');
        expect((meals.single! as Map)['oil_level'], 'home');

        final csv = files.last.content;
        expect(csv, contains('"Moong Dal, Home Style"'));
        expect(csv, contains('katori,home,165.0'));
      });
    },
  );

  testWidgets('EditDetailsScreen exports data offline in one tap', (
    tester,
  ) async {
    final share = _CapturedShare();
    await withClock(Clock.fixed(testNow), () async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(db.close);
      await tester.runAsync(
        () => ProfileRepository(db).saveProfile(
          ProfileAnswers(
            goal: GoalType.maintain,
            birthDate: DateTime(1998, 3, 14),
            sex: Sex.male,
            heightCm: 175,
            weightKg: 70,
            activity: ActivityLevel.active,
          ),
        ),
      );

      tester.view
        ..physicalSize = const Size(1080, 2400)
        ..devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            shareServiceProvider.overrideWithValue(share),
            dataExporterProvider.overrideWithValue(DataExporter(db)),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Consumer(
                builder: (context, ref, _) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      final files = await ref
                          .read(dataExporterProvider)
                          .buildExport();
                      await ref.read(shareServiceProvider).shareFiles(files);
                    },
                    child: const Text('Export'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      expect(share.last, hasLength(2));
      expect(share.last.first.name, 'aurafit-export.json');
      expect(share.last.first.content, contains('"formula_version": "v2"'));
    });
  });
}
