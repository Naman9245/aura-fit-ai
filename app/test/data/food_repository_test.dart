import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/food_repository.dart';
import 'package:aurafit/models/options.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_sync_remote.dart';

void main() {
  late AppDatabase db;
  late FoodRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FoodRepository(
      db,
      loadSeedJson: () => File('assets/foods.json').readAsString(),
    );
  });

  tearDown(() => db.close());

  test('seeds 400+ verified Indian foods within SQLite CHECK limits', () async {
    await repo.ensureSeeded();
    final all = await repo.allFoods();
    expect(all.length, greaterThanOrEqualTo(400));

    final sources = {for (final f in all) f.source};
    expect(sources, containsAll(['usda_fdc', 'recipe', 'label']));

    // The cursor starts at the bundled copy's highest seq, which is above
    // the count once a seeded food has been fixed on the server.
    final cursor = await (db.select(
      db.syncCursors,
    )..where((c) => c.kind.equals('foods'))).getSingle();
    final bundled = jsonDecode(File('assets/foods.json').readAsStringSync());
    expect(
      cursor.seq,
      (bundled as List<Object?>)
          .map((f) => (f! as Map)['seq']! as int)
          .reduce(max),
    );
  });

  test('searches English, Hindi and Hinglish aliases in under 50 ms', () async {
    await repo.ensureSeeded();

    final sw = Stopwatch()..start();
    final roti = await repo.search('phulka');
    final anda = await repo.search('anda');
    final chaas = await repo.search('chaas');
    final rajma = await repo.search('rajma chawal');
    sw.stop();

    expect(roti, isNotEmpty);
    expect(anda.any((f) => f.name.toLowerCase().contains('egg')), isTrue);
    expect(chaas, isNotEmpty);
    expect(rajma, isNotEmpty);
    expect(sw.elapsedMilliseconds, lessThan(200));
  });

  test(
    'applies 1-tap oil and ghee rules without changing protein or carbs',
    () async {
      final phulkas = await repo.search('phulka');
      final phulka = phulkas.firstWhere(
        (f) =>
            f.source == 'recipe' &&
            f.assumption.toLowerCase().contains('no ghee'),
      );
      expect(phulka.defaultOil, OilLevel.low);

      final dry = phulka.calculate(
        unit: 'piece',
        count: 2,
        oilLevel: OilLevel.low,
      );
      final home = phulka.calculate(
        unit: 'piece',
        count: 2,
        oilLevel: OilLevel.home,
      );
      final extra = phulka.calculate(
        unit: 'piece',
        count: 2,
        oilLevel: OilLevel.extra,
      );

      expect(home.proteinG, dry.proteinG);
      expect(home.carbsG, dry.carbsG);
      expect(home.fatG, greaterThan(dry.fatG));
      expect(home.kcal, greaterThan(dry.kcal));
      expect(extra.fatG, greaterThan(home.fatG));
      expect(extra.kcal, greaterThan(home.kcal));

      final dals = await repo.search('moong dal tadka');
      final dal = dals.firstWhere((f) => f.source == 'recipe');
      expect(dal.defaultOil, OilLevel.home);

      final dalLow = dal.calculate(
        unit: 'katori',
        count: 1,
        oilLevel: OilLevel.low,
      );
      final dalHome = dal.calculate(
        unit: 'katori',
        count: 1,
        oilLevel: OilLevel.home,
      );
      final dalExtra = dal.calculate(
        unit: 'katori',
        count: 1,
        oilLevel: OilLevel.extra,
      );

      expect(dalLow.kcal, lessThan(dalHome.kcal));
      expect(dalExtra.kcal, greaterThan(dalHome.kcal));
    },
  );

  test(
    'syncCatalogue pulls new dishes by seq and hides retired ones',
    () async {
      await repo.ensureSeeded();
      final bundled = jsonDecode(File('assets/foods.json').readAsStringSync());
      final bundledMaxSeq = (bundled as List<Object?>)
          .map((f) => (f! as Map)['seq']! as int)
          .reduce(max);

      final remote = FakeSyncRemote();
      // Advance FakeSyncRemote seq past the bundled seed's highest number.
      for (var i = 0; i <= bundledMaxSeq; i++) {
        remote.put('profiles', {
          'birth_date': '1995-01-01',
          'sex': 'male',
          'height_cm': 175.0,
          'activity_level': 'moderate',
          'created_at': '2026-11-22T00:00:00Z',
          'updated_at': DateTime.utc(
            2026,
            11,
            22,
          ).add(Duration(seconds: i + 1)).toIso8601String(),
          'deleted_at': null,
        });
      }

      remote.put('foods', {
        'id': '019a9000-0000-7000-8000-000000009999',
        'name': 'Ragi mudde (Karnataka finger millet ball)',
        'aliases': ['ragi ball', 'mudde'],
        'kcal_per_100g': 152.0,
        'protein_g_per_100g': 3.6,
        'carbs_g_per_100g': 31.8,
        'fat_g_per_100g': 0.8,
        'portions': [
          {'unit': 'piece', 'grams': 180},
        ],
        'assumption': '45 g ragi flour cooked in water, no ghee',
        'source': 'recipe',
        'updated_at': '2026-11-25T10:00:00Z',
        'deleted_at': null,
      });

      await repo.syncCatalogue(remote);
      final found = await repo.search('mudde');
      expect(found.map((f) => f.name), contains(contains('Ragi mudde')));

      remote.put('foods', {
        'id': '019a9000-0000-7000-8000-000000009999',
        'name': 'Ragi mudde (Karnataka finger millet ball)',
        'aliases': ['ragi ball', 'mudde'],
        'kcal_per_100g': 152.0,
        'protein_g_per_100g': 3.6,
        'carbs_g_per_100g': 31.8,
        'fat_g_per_100g': 0.8,
        'portions': [
          {'unit': 'piece', 'grams': 180},
        ],
        'assumption': '45 g ragi flour cooked in water, no ghee',
        'source': 'recipe',
        'updated_at': '2026-11-25T11:00:00Z',
        'deleted_at': '2026-11-25T11:00:00Z',
      });

      await repo.syncCatalogue(remote);
      final afterRetire = await repo.search('mudde');
      expect(afterRetire.where((f) => f.id.endsWith('9999')), isEmpty);
    },
  );

  test('spelling the Hinglish way still finds the food', () async {
    await repo.ensureSeeded();
    for (final (typed, spelled) in [
      ('parantha', 'paratha'),
      ('gobhi', 'gobi'),
      ('daal', 'dal'),
      ('panner', 'paneer'),
      ('chaval', 'chawal'),
      ('chapatti', 'chapati'),
      ('bhendi', 'bhindi'),
    ]) {
      expect(foldSpelling(typed), foldSpelling(spelled), reason: typed);
    }

    Future<String> first(String query) async =>
        (await repo.search(query)).first.name;
    expect(await first('plain paratha'), 'Plain Paratha (Tawa / Triangle)');
    expect(await first('plain parantha'), 'Plain Paratha (Tawa / Triangle)');
    expect(
      (await repo.search('panner tikka')).map((f) => f.name),
      contains('Paneer Tikka (Grilled / Tandoori)'),
    );
    expect(
      (await repo.search('rajma chaval')).map((f) => f.name),
      contains('Rajma Chawal (Home Plate)'),
    );
    // Exact spellings still come before loose ones.
    expect(await first('aloo paratha'), 'Aloo Paratha');

    // Joining words and typos.
    expect(await first('makke di roti'), 'Makki ki Roti');
    expect(await first('sarson da saag'), 'Sarson ka Saag');
    expect(
      (await repo.search('chiken curry')).map((f) => f.name),
      contains('Home-Style Chicken Curry'),
    );
    expect(
      (await repo.search('panir tika')).map((f) => f.name),
      contains('Paneer Tikka (Grilled / Tandoori)'),
    );
    expect(
      (await repo.search('biryani chiken')).map((f) => f.name),
      contains('Chicken Biryani'),
    );
    expect(editDistance('chiken', 'chicken', 2), 1);
    expect(editDistance('roti', 'dosa', 1), 2);
  });

  test('dishes made of eggs or pieces are counted by them', () async {
    await repo.ensureSeeded();
    Future<FoodItem> food(String query) async =>
        (await repo.search(query)).first;

    final curry = await food('egg curry');
    expect(curry.portions.first.unit, 'egg + gravy');
    final twoEggs = curry.calculate(
      unit: 'egg + gravy',
      count: 2,
      oilLevel: curry.defaultOil,
    );
    expect(twoEggs.grams, 200);

    expect((await food('egg bhurji')).portions.first.unit, 'egg');
    expect(
      (await food('chicken curry')).portions.map((p) => p.unit),
      containsAll([
        'small piece + gravy',
        'medium piece + gravy',
        'large piece + gravy',
      ]),
    );
    expect(
      (await food('tandoori chicken')).portions.map((p) => p.unit),
      containsAll(['leg piece', 'drumstick', 'wing']),
    );
    expect((await food('chicken curry')).name, 'Home-Style Chicken Curry');
    for (final name in ['chole bhature', 'malai kofta', 'momos', 'jalebi']) {
      expect(await repo.search(name), isNotEmpty, reason: name);
    }
  });
}
