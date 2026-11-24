import 'dart:io';
import 'dart:ui' as ui;

import 'package:aurafit/app.dart';
import 'package:aurafit/core/router.dart';
import 'package:aurafit/data/account.dart';
import 'package:aurafit/data/db/app_database.dart';
import 'package:aurafit/data/providers.dart';
import 'package:aurafit/data/sync/sync_controller.dart';
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
        await _tap(tester, 'Continue');

        await _shot(tester, '09_training$suffix');
        await _tap(tester, 'Skip');

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

Future<void> _tap(WidgetTester tester, String text) async {
  // Rebuild first, so a button enabled by the last change is tappable.
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _pump(WidgetTester tester, double textScale) async {
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
        child: const AuraApp(startAt: Routes.onboarding),
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

/// Roboto and the Material icons, as an Android phone has them. Tests draw
/// with a stand-in font otherwise.
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
}
