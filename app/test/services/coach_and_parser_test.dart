import 'dart:io';

import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/food_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:aurafit/services/coach_rules.dart';
import 'package:aurafit/services/meal_text_parser.dart';
import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeParseRemote implements MealParseRemote {
  _FakeParseRemote({this.items = const [], this.error});

  @override
  bool isConfigured = true;

  List<RawAiMealItem> items;
  MealParseFallbackReason? error;
  int calls = 0;

  @override
  Future<List<RawAiMealItem>> parseText(String text) async {
    calls += 1;
    if (error case final reason?) {
      throw MealParseFallbackException(reason);
    }
    return items;
  }
}

void main() {
  group('evaluateDayFeedback (PRD D4)', () {
    test('over target but below maintenance shows calm amber with facts', () {
      final fb = evaluateDayFeedback(
        eatenKcal: 1720,
        targetKcal: 1600,
        maintenanceKcal: 1950,
        sex: Sex.female,
        isToday: true,
        currentHour: 20,
        mealCount: 3,
      );
      expect(fb.isAmber, isTrue);
      expect(fb.message, contains('120 kcal over target'));
      expect(fb.message, contains('still below what your body uses'));
      expect(fb.message, contains('One day doesn\'t change the week'));
    });

    test('wedding day above maintenance points calmly to 7-day average', () {
      final fb = evaluateDayFeedback(
        eatenKcal: 2400,
        targetKcal: 1600,
        maintenanceKcal: 1950,
        sex: Sex.female,
        isToday: true,
        currentHour: 22,
        mealCount: 4,
      );
      expect(fb.isAmber, isTrue);
      expect(fb.message, contains('800 kcal over target'));
      expect(fb.message, contains('7-day average'));
    });

    test('never praises eating too little in the evening', () {
      final fb = evaluateDayFeedback(
        eatenKcal: 800,
        targetKcal: 1600,
        maintenanceKcal: 1950,
        sex: Sex.female,
        isToday: true,
        currentHour: 20,
        mealCount: 2,
      );
      expect(fb.isAmber, isTrue);
      expect(fb.message, contains('is a meal missing?'));
      expect(fb.message, contains('1,200 kcal'));
    });
  });

  group('buildProteinGuidance (PRD C5)', () {
    test('strictly respects vegetarian, vegan, egg and non-veg diets', () {
      final veg = buildProteinGuidance(
        dietType: DietType.veg,
        targetProteinG: 110,
        eatenProteinG: 40,
        targetKcal: 1800,
        eatenKcal: 900,
        sex: Sex.female,
      );
      expect(veg.proteinLeftG, 70);
      expect(veg.ideas, isNotEmpty);
      for (final idea in veg.ideas) {
        final lower = idea.dish.toLowerCase();
        expect(lower.contains('egg'), isFalse);
        expect(lower.contains('chicken'), isFalse);
        expect(lower.contains('fish'), isFalse);
      }
      expect(veg.floorNote, contains('1,200 kcal safe minimum'));

      final vegan = buildProteinGuidance(
        dietType: DietType.vegan,
        targetProteinG: 100,
        eatenProteinG: 50,
        targetKcal: 1800,
        eatenKcal: 1400,
        sex: Sex.male,
      );
      for (final idea in vegan.ideas) {
        final lower = idea.dish.toLowerCase();
        expect(lower.contains('paneer'), isFalse);
        expect(lower.contains('yogurt'), isFalse);
        expect(lower.contains('egg'), isFalse);
        expect(lower.contains('chicken'), isFalse);
      }
      expect(vegan.floorNote, contains('1,500 kcal safe minimum'));

      final done = buildProteinGuidance(
        dietType: DietType.nonVeg,
        targetProteinG: 120,
        eatenProteinG: 118,
        targetKcal: 2200,
        eatenKcal: 2000,
        sex: Sex.male,
      );
      expect(done.ideas, isEmpty);
    });
  });

  group('MealTextParser (PRD N2)', () {
    late AppDatabase db;
    late FoodRepository foods;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      foods = FoodRepository(
        db,
        loadSeedJson: () => File('assets/foods.json').readAsString(),
      );
    });

    tearDown(() => db.close());

    test('matches verified catalogue first and marks unknown dishes as AI estimates', () async {
      final remote = _FakeParseRemote(
        items: const [
          RawAiMealItem(
            name: 'Plain Roti',
            searchQuery: 'phulka',
            quantity: 2,
            unit: 'piece',
            oilLevel: OilLevel.low,
            estimatedGrams: 80,
            kcal: 999, // Wild AI hallucination ignored when DB matches!
            proteinG: 99,
            carbsG: 99,
            fatG: 99,
            confidence: ParseConfidence.high,
          ),
          RawAiMealItem(
            name: 'Grandma secret jackfruit halwa',
            searchQuery: 'secret jackfruit halwa',
            quantity: 1,
            unit: 'bowl',
            oilLevel: OilLevel.extra,
            estimatedGrams: 120,
            kcal: 340,
            proteinG: 3.5,
            carbsG: 48,
            fatG: 15,
            confidence: ParseConfidence.low,
          ),
        ],
      );
      final parser = MealTextParser(foods, remote);

      final drafts = await parser.parse(
        '2 phulka without ghee and grandma secret jackfruit halwa',
      );
      expect(drafts, hasLength(2));

      // First item uses verified food database macros, NOT 999 kcal!
      expect(drafts[0].isVerifiedMatch, isTrue);
      expect(drafts[0].kcal, lessThan(250));
      expect(drafts[0].oilLevel, OilLevel.low);

      // Second item falls back to AI estimate and never enters `foods`.
      expect(drafts[1].isVerifiedMatch, isFalse);
      expect(drafts[1].kcal, 340);
      expect(drafts[1].confidence, ParseConfidence.low);

      final foodCount = (await foods.allFoods()).length;
      expect(
        (await foods.search('secret jackfruit halwa')),
        isEmpty,
        reason: 'AI estimates must never write to the shared food catalogue',
      );
      expect(foodCount, greaterThanOrEqualTo(400));
    });

    test(
      'opens circuit breaker after 3 failures and resets after cooldown',
      () async {
        final remote = _FakeParseRemote(
          error: MealParseFallbackReason.aiUnavailable,
        );
        final parser = MealTextParser(foods, remote);
        final start = DateTime(2026, 11, 25, 12);

        await withClock(Clock.fixed(start), () async {
          for (var i = 0; i < 3; i++) {
            await expectLater(
              parser.parse('2 idli'),
              throwsA(isA<MealParseFallbackException>()),
            );
          }
          expect(remote.calls, 3);

          // 4th call short-circuits immediately without calling remote.
          await expectLater(
            parser.parse('2 idli'),
            throwsA(isA<MealParseFallbackException>()),
          );
          expect(remote.calls, 3);
        });

        // After 3 minutes cooldown, circuit closes and tries again.
        remote
          ..error = null
          ..items = const [];
        await withClock(
          Clock.fixed(start.add(const Duration(minutes: 3))),
          () async {
            final res = await parser.parse('2 idli');
            expect(res, isEmpty);
            expect(remote.calls, 4);
          },
        );
      },
    );
  });
}
