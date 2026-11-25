import 'dart:io';

import 'package:aurafit/app.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/food_repository.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/meal_text_parser.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

class _StubParseRemote implements MealParseRemote {
  _StubParseRemote({this.items = const []});

  @override
  bool isConfigured = true;

  List<RawAiMealItem> items;
  MealParseFallbackReason? error;

  @override
  Future<List<RawAiMealItem>> parseText(String text) async {
    if (error case final reason?) {
      throw MealParseFallbackException(reason);
    }
    return items;
  }
}

Future<AppDatabase> _pumpToday(
  WidgetTester tester, {
  _StubParseRemote? parseRemote,
  Future<void> Function(AppDatabase db)? extraSeed,
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
  addTearDown(db.close);
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

  final seedJson = await tester.runAsync(
    () => File('assets/foods.json').readAsString(),
  );
  final foodRepo = FoodRepository(db, loadSeedJson: () async => seedJson!);

  await tester.runAsync(() async {
    await ProfileRepository(db).saveProfile(
      ProfileAnswers(
        goal: GoalType.loseFat,
        birthDate: DateTime(1998, 5, 10),
        sex: Sex.female,
        heightCm: 162,
        weightKg: 65,
        activity: ActivityLevel.lightlyActive,
        diet: DietType.veg,
      ),
    );
    if (extraSeed != null) await extraSeed(db);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        foodRepositoryProvider.overrideWithValue(foodRepo),
        if (parseRemote != null)
          mealParseRemoteProvider.overrideWithValue(parseRemote),
      ],
      child: const AuraApp(startAt: Routes.today),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}

Finder _verticalScrollable() => find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
);

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final verticals = _verticalScrollable();
  if (target.evaluate().isEmpty && verticals.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(target, 180, scrollable: verticals.last);
  }
  if (Scrollable.maybeOf(tester.element(target.first)) != null) {
    await Scrollable.ensureVisible(
      tester.element(target.first),
      alignment: 0.35,
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await _scrollTo(tester, target);
  await tester.tap(target.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Today searches foods offline, switches oil level, edits/deletes entries, and undoes 250 ml water',
    (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        final db = await _pumpToday(tester);

        // Diet-matched vegetarian protein ideas appear (PRD C5).
        expect(find.textContaining('protein left today'), findsOneWidget);
        expect(find.text('Vegetarian'), findsOneWidget);

        // 1-tap +250 ml water and 1-tap Undo (PRD N5, N11).
        await _scrollTo(tester, find.text('250 ml'));
        await tester.tap(find.text('250 ml'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.textContaining('0.25 L /'), findsOneWidget);
        await tester.tap(find.text('Undo'));
        await tester.pumpAndSettle();
        expect(find.textContaining('0 L /'), findsOneWidget);

        // Search & log Phulka with Home style ghee (PRD N1, N9).
        await _tap(tester, 'Log food');
        await tester.enterText(
          find.widgetWithText(TextField, 'Search Indian foods & staples'),
          'phulka',
        );
        await tester.pumpAndSettle();
        await _tap(tester, 'Phulka / Plain Roti');

        // Shows explicit recipe assumption and oil choices.
        expect(find.textContaining('Assumes:'), findsOneWidget);
        await _tap(tester, '2');
        await _tap(tester, 'Home style');
        await _tap(tester, 'Add to breakfast');

        // Back on Today: entry shows portion and oil choice.
        await _scrollTo(tester, find.textContaining('2 piece · Home style'));
        expect(find.textContaining('2 piece · Home style'), findsOneWidget);

        // Tap logged entry to remove it, then verify soft-delete (PRD N11).
        await tester.tap(find.textContaining('2 piece · Home style'));
        await tester.pumpAndSettle();
        await _tap(tester, 'Remove entry');
        expect(find.textContaining('2 piece · Home style'), findsNothing);

        // Log 6 boiled eggs via the scrollable wheel without opening keyboard.
        await _tap(tester, 'Log food');
        await tester.enterText(
          find.widgetWithText(TextField, 'Search Indian foods & staples'),
          'boiled whole egg',
        );
        await tester.pumpAndSettle();
        await _tap(tester, 'Boiled Whole Egg');
        expect(find.text('1 egg  (50 g)'), findsOneWidget);

        // Spin the horizontal wheel left to log multiple eggs without keyboard.
        await tester.drag(
          find.byType(ListWheelScrollView),
          const Offset(-450, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text('1 egg  (50 g)'), findsNothing);
        await _tap(tester, 'Add to breakfast');

        final allRows = await tester.runAsync(
          () => db.select(db.mealEntries).get(),
        );
        expect(allRows, hasLength(2));
        expect(allRows!.first.deletedAt, isNotNull);
        expect(allRows.last.portionUnit, 'egg');
        expect(allRows.last.portionCount, greaterThan(1));
      });
    },
  );

  testWidgets(
    'repeats yesterday\'s breakfast in 1 tap and shows 7-day average on an over-target day',
    (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        final yesterday = DateTime(
          testNow.year,
          testNow.month,
          testNow.day - 1,
        );
        await _pumpToday(
          tester,
          extraSeed: (db) => LogRepository(db).logEntry(
            NewMealEntry(
              name: 'Poha',
              meal: Meal.breakfast,
              day: yesterday,
              portionUnit: 'katori',
              portionCount: 1,
              oilLevel: OilLevel.home,
              grams: 150,
              kcal: 240,
              proteinG: 5,
              carbsG: 42,
              fatG: 6,
              source: EntrySource.search,
            ),
          ),
        );

        // Repeat yesterday's breakfast in 1 tap (PRD N3).
        await _scrollTo(
          tester,
          find.textContaining('Repeat yesterday (1 item · 240 kcal)'),
        );
        expect(
          find.textContaining('Repeat yesterday (1 item · 240 kcal)'),
          findsOneWidget,
        );
        await _tap(tester, 'Repeat yesterday (1 item · 240 kcal)');
        expect(find.text('Poha'), findsWidgets);

        // Log a big wedding feast via Quick add offline (PRD N12, D2, D4).
        await _tap(tester, 'Log food');
        await _tap(tester, 'Quick add');
        await tester.enterText(
          find.widgetWithText(TextField, 'Dish name'),
          'Wedding thali feast',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Calories'),
          '2100',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Protein (opt)'),
          '55',
        );
        await _tap(tester, 'Add to breakfast');

        // Scroll back up to summary card to verify calm amber feedback & 7-day avg.
        await tester.drag(_verticalScrollable().first, const Offset(0, 600));
        await tester.pumpAndSettle();
        expect(find.textContaining('kcal over target'), findsOneWidget);
        expect(
          find.textContaining('One day doesn\'t change the week'),
          findsOneWidget,
        );
        expect(find.textContaining('2 days logged'), findsOneWidget);
      });
    },
  );

  testWidgets(
    'AI Type meal shows edit-before-save drafts and falls back cleanly when offline',
    (tester) async {
      await withClock(Clock.fixed(testNow), () async {
        final remote = _StubParseRemote(
          items: const [
            RawAiMealItem(
              name: 'Plain Roti',
              searchQuery: 'phulka',
              quantity: 2,
              unit: 'piece',
              oilLevel: OilLevel.low,
              estimatedGrams: 80,
              kcal: 194,
              proteinG: 6.9,
              carbsG: 40.5,
              fatG: 1.0,
              confidence: ParseConfidence.high,
            ),
            RawAiMealItem(
              name: 'Hostel special curry',
              searchQuery: 'mystery hostel special',
              quantity: 1,
              unit: 'katori',
              oilLevel: OilLevel.home,
              estimatedGrams: 150,
              kcal: 210,
              proteinG: 7,
              carbsG: 18,
              fatG: 12,
              confidence: ParseConfidence.low,
            ),
          ],
        );

        await _pumpToday(tester, parseRemote: remote);
        await _tap(tester, 'Type');
        await tester.enterText(
          find.widgetWithText(TextField, 'What did you eat?'),
          '2 roti and 1 katori hostel special curry',
        );
        await _tap(tester, 'Read meal');

        expect(find.text('Check and adjust before saving'), findsOneWidget);
        expect(find.textContaining('Verified food match'), findsOneWidget);
        await _scrollTo(
          tester,
          find.textContaining('AI estimate, tap to adjust'),
        );
        expect(
          find.textContaining('AI estimate, tap to adjust'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Low confidence — check portion'),
          findsOneWidget,
        );

        await _tap(tester, 'Save 2 items (404 kcal)');
        await _scrollTo(tester, find.text('Hostel special curry'));
        expect(find.text('Hostel special curry'), findsWidgets);

        // Now go offline: AI Type falls back smoothly to Search / Quick add.
        remote.error = MealParseFallbackReason.offline;
        await _tap(tester, 'Type');
        await tester.enterText(
          find.widgetWithText(TextField, 'What did you eat?'),
          '1 katori dal',
        );
        await _tap(tester, 'Read meal');

        expect(find.text('You\'re offline right now.'), findsOneWidget);
        await _tap(tester, 'Quick add');
        expect(find.widgetWithText(TextField, 'Dish name'), findsOneWidget);
      });
    },
  );
}
