import 'dart:io';
import 'dart:ui' as ui;

import 'package:aurafit/app.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/log_repository.dart';
import 'package:aurafit/data/profile_repository.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/data/sync/sync_controller.dart';
import 'package:aurafit/features/shell/app_shell.dart';
import 'package:aurafit/models/options.dart';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/helpers/fake_account_service.dart';
import '../test/helpers/fake_sync_remote.dart';

// Draws every screen on a phone-sized screen with the phone's real font,
// at normal and large text, to look the app over without a phone:
//
//   flutter test tool/screenshots_test.dart
//
// The pictures land in build/screenshots/.

const _out = 'build/screenshots';
final _app = GlobalKey();

void main() {
  for (final (scale, suffix) in [(1.0, ''), (1.3, '_large_text')]) {
    testWidgets('render the intro$suffix', (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 11, 22, 9)), () async {
        await _loadFonts();
        // Josh at rest: he moves for ever otherwise.
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await _pump(tester, scale, startAt: Routes.intro);

        await _shot(tester, '00a_intro_hello$suffix');
        await _tap(tester, 'Hi Josh');
        await _shot(tester, '00b_intro_plan$suffix');
        await _tap(tester, 'Next');
        await _shot(tester, '00c_intro_coach$suffix');
        await _tap(tester, 'Next');
        await _shot(tester, '00d_intro_food$suffix');
        await _tap(tester, 'Next');
        await _shot(tester, '00e_intro_together$suffix');
      });
    });

    testWidgets('render the tabs$suffix', (tester) async {
      final now = DateTime(2026, 11, 26, 13);
      await withClock(Clock.fixed(now), () async {
        await _loadFonts();
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        await _pump(
          tester,
          scale,
          startAt: Routes.today,
          seed: (db) => _seedDiary(db, now),
        );

        await _shot(tester, '20_today$suffix');
        await _scroll(tester, -700);
        await _shot(tester, '21_today_more$suffix');
        await _tapTab(tester, 'Food');
        await _shot(tester, '22_food$suffix');
        await _tap(tester, 'Search Indian foods');
        await tester.enterText(_field('Search Indian foods & staples'), 'egg');
        await _shot(tester, '22a_log_search$suffix');
        await _tap(tester, 'Egg Curry (AndaTari)');
        await _shot(tester, '22b_food_sheet$suffix');
        Navigator.of(tester.element(find.text('OIL & GHEE'))).pop();
        await tester.pumpAndSettle();
        await _tap(tester, 'Quick add');
        await _shot(tester, '22c_quick_add$suffix');
        await tester.pageBack();
        await tester.pumpAndSettle();
        await _scroll(tester, -900);
        await _shot(tester, '23_food_meals$suffix');
        await _tapTab(tester, 'Progress');
        await _shot(tester, '24_progress$suffix');
        await tester.tap(find.bySemanticsLabel('24 November: logged'));
        await tester.pumpAndSettle();
        await _shot(tester, '24a_progress_day$suffix');
        Navigator.of(tester.element(find.text('TUESDAY 24 NOVEMBER'))).pop();
        await tester.pumpAndSettle();
        await _scroll(tester, -700);
        await _shot(tester, '25_progress_weight$suffix');
        await _tapTab(tester, 'Train');
        await _shot(tester, '26_train$suffix');
        await _scroll(tester, -700);
        await _shot(tester, '26a_train_exercises$suffix');
        await _scroll(tester, 700);
        await _tap(tester, 'Start workout');
        await tester.tap(find.bySemanticsLabel('Mark set 1 done').first);
        await tester.pumpAndSettle();
        await _shot(tester, '27_workout$suffix');
      });
    });

    testWidgets('render every screen$suffix', (tester) async {
      await withClock(Clock.fixed(DateTime(2026, 11, 22, 9)), () async {
        await _loadFonts();
        await _pump(tester, scale);

        await _shot(tester, '01_goal$suffix');
        await _tap(tester, 'Lose fat');
        await _shot(tester, '02_goal_chosen$suffix');
        await _tap(tester, 'Continue');

        await tester.enterText(_field('Day'), '10');
        await tester.enterText(_field('Month'), '5');
        await tester.enterText(_field('Year'), '1996');
        await _shot(tester, '03_birth_date$suffix');
        await _tap(tester, 'Continue');

        await _tap(tester, 'Female');
        await _shot(tester, '04_sex$suffix');
        await _tap(tester, 'Continue');

        await tester.enterText(_field('Feet'), '5');
        await tester.enterText(_field('Inches'), '1');
        await _shot(tester, '05a_body_feet$suffix');
        await _tap(tester, 'cm');
        await tester.enterText(_field('Height'), '155');
        await tester.enterText(_field('Weight'), '50');
        await _shot(tester, '05_body$suffix');
        await tester.enterText(_field('Height'), '300');
        await _shot(tester, '06_body_error$suffix');
        await tester.enterText(_field('Height'), '155');
        await _tap(tester, 'Continue');

        await _tap(tester, 'Mostly sitting');
        await _shot(tester, '07_activity$suffix');
        await _tap(tester, 'Continue');

        await _tap(tester, 'Vegetarian');
        await _shot(tester, '08_diet$suffix');
        await _tap(tester, 'See my targets');

        await _shot(tester, '10_targets_floor$suffix');
        await _tap(tester, 'How we calculated this');
        await _shot(tester, '11_how$suffix');
        await _scroll(tester, -900);
        await _shot(tester, '12_how_more$suffix');
        await _scroll(tester, -1500);
        await _shot(tester, '13_how_end$suffix');
        await tester.pageBack();
        await tester.pumpAndSettle();

        await _tap(tester, 'Save my plan');
        await _shot(tester, '14_sign_in$suffix');
        await tester.tap(find.byType(Checkbox));
        await tester.enterText(_field('Email'), 'priya@example.com');
        await tester.enterText(_field('Password'), 'long-enough-password');
        await _shot(tester, '15_sign_in_filled$suffix');
        await _tap(tester, 'Create account');
        await tester.enterText(_field('Code'), FakeAccountService.code);
        await _shot(tester, '16_code$suffix');
        await _tap(tester, 'Confirm');
        await _shot(tester, '17_targets_saved$suffix');
        await tester.tap(find.byTooltip('Account'));
        await _shot(tester, '18_account$suffix');
        await _tap(tester, 'Sign out');
        await _shot(tester, '19_sign_out$suffix');
      });
    });
  }
}

Finder _field(String label) => find.widgetWithText(TextField, label);

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(AuraTabBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

/// Two weeks of meals this month, water and steps today, and twelve weeks
/// of weigh-ins, as someone a fortnight in would have.
Future<void> _seedDiary(AppDatabase db, DateTime now) async {
  await ProfileRepository(db).saveProfile(
    ProfileAnswers(
      goal: GoalType.loseFat,
      birthDate: DateTime(1996, 5, 10),
      sex: Sex.female,
      heightCm: 160,
      weightKg: 63.9,
      activity: ActivityLevel.lightlyActive,
      diet: DietType.veg,
    ),
  );
  final log = LogRepository(db);
  final today = DateTime(now.year, now.month, now.day);
  Future<void> meal(
    DateTime day,
    Meal meal,
    String name,
    double kcal,
    double protein, {
    String unit = 'katori',
    double count = 1,
  }) => log.logEntry(
    NewMealEntry(
      name: name,
      meal: meal,
      day: day,
      portionUnit: unit,
      portionCount: count,
      oilLevel: OilLevel.home,
      grams: 150 * count,
      kcal: kcal,
      proteinG: protein,
      carbsG: kcal * 0.12,
      fatG: kcal * 0.03,
      source: EntrySource.search,
    ),
  );
  for (final d in [2, 3, 5, 6, 9, 10, 12, 16, 17, 19, 20, 23, 24]) {
    final day = DateTime(now.year, now.month, d);
    await meal(day, Meal.breakfast, 'Poha', 270, 6, unit: 'plate');
    await meal(day, Meal.lunch, 'Rajma', 240, 11);
  }
  await meal(today, Meal.breakfast, 'Poha', 270, 6, unit: 'plate');
  await meal(
    today,
    Meal.lunch,
    'Phulka / Plain Roti',
    194,
    7,
    unit: 'piece',
    count: 2,
  );
  await meal(today, Meal.lunch, 'Moong Dal', 160, 10);
  await meal(today, Meal.snack, 'Curd', 98, 5);
  for (var i = 0; i < 6; i++) {
    await log.addWater(day: today);
  }
  await log.setStepsForDay(day: today, steps: 6400);
  await ProfileRepository(db).saveTraining(
    place: TrainingPlace.gym,
    days: 4,
    experience: Experience.intermediate,
  );
  const kg = [
    66.0,
    65.8,
    65.9,
    65.5,
    65.2,
    65.3,
    64.9,
    64.6,
    64.7,
    64.3,
    64.1,
    63.9,
  ];
  for (var week = 0; week < kg.length; week++) {
    final day = DateTime(today.year, today.month, today.day - 7 * (11 - week));
    await log.saveWeightForDay(day: day, weightKg: kg[week]);
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  // Rebuild first, so a button enabled by the last change is tappable.
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester,
  double textScale, {
  String startAt = Routes.onboarding,
  Future<void> Function(AppDatabase db)? seed,
}) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  if (seed != null) await tester.runAsync(() => seed(db));
  await tester.pumpWidget(
    RepaintBoundary(
      key: _app,
      child: ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // Signing in and syncing with stand-ins, so no network is needed.
          accountServiceProvider.overrideWithValue(FakeAccountService()),
          syncRemoteProvider.overrideWithValue(FakeSyncRemote()),
        ],
        child: AuraApp(startAt: startAt),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Drags the topmost list by [dy].
Future<void> _scroll(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(Scrollable).hitTestable().first, Offset(0, dy));
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary =
      _app.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(
      pixelRatio: tester.view.devicePixelRatio,
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File('$_out/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

/// The app's bundled fonts, plus Roboto and the Material icons as an Android
/// phone has them. Tests draw with a stand-in font otherwise.
Future<void> _loadFonts() async {
  // flutter_tester sits in bin/cache/artifacts/engine/<platform>/.
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
  final fonts = '${artifacts.path}/material_fonts';

  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final file in files) {
      loader.addFont(
        Future.value(ByteData.sublistView(File(file).readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await family('Roboto', [
    for (final weight in ['regular', 'medium', 'bold', 'light'])
      '$fonts/roboto-$weight.ttf',
  ]);
  await family('MaterialIcons', ['$fonts/materialicons-regular.otf']);
  await family('DMSans', [
    for (final weight in ['Regular', 'Medium', 'Bold'])
      'assets/fonts/DMSans-$weight.ttf',
  ]);
  await family('BarlowCondensed', [
    'assets/fonts/BarlowCondensed-ExtraBold.ttf',
  ]);
}
