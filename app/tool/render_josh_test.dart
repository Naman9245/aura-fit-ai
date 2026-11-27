import 'dart:io';
import 'dart:ui' as ui;

import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:aurafit/widgets/josh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Draws every one of Josh's stages and moods on one sheet, to look him over
// after changing his painter:
//
//   flutter test tool/render_josh_test.dart
//
// The sheet lands in build/josh/sheet.png.

void main() {
  testWidgets('render Josh', (tester) async {
    final barlow = FontLoader('BarlowCondensed')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/BarlowCondensed-ExtraBold.ttf')
                .readAsBytesSync(),
          ),
        ),
      );
    await barlow.load();

    const backgrounds = [
      AuraColors.sky,
      AuraColors.lilacLight,
      AuraColors.mint,
      AuraColors.yellow,
      AuraColors.ink,
      Color(0xFF24212E),
    ];
    const cell = 180.0;
    final width = cell * JoshMood.values.length;
    final height = cell * 1.15 * JoshStage.values.length;
    tester.view
      ..physicalSize = Size(width, height)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: key,
            child: Column(
              children: [
                for (final stage in JoshStage.values)
                  Row(
                    children: [
                      for (final (i, mood) in JoshMood.values.indexed)
                        ColoredBox(
                          color: backgrounds[i],
                          child: Josh(mood: mood, stage: stage, width: cell),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    File('build/josh/sheet.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!);
  });
}
