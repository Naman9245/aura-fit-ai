import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// Draws the app icon from code: Today's calorie ring, most of the way
// round, in the app's orange on its dark blue. Run after changing it:
//
//   flutter test tool/render_icon_test.dart
//   dart run flutter_launcher_icons
//
// flutter_launcher_icons (configured in pubspec.yaml) turns these into the
// Android launcher icons.

/// Where the images go, beside the config in pubspec.yaml that uses them.
const _out = 'assets/icon';

void main() {
  testWidgets('render the app icon', (tester) async {
    // The full icon, for old launchers and the Play Store: the ring fills
    // most of the square.
    await _render(
      tester,
      'icon.png',
      AuraColors.black,
      AuraColors.accent,
      0.62,
    );
    // The adaptive icon's front layer: launchers crop to a circle about 2/3
    // of the square wide, so the ring sits well inside it, on nothing.
    await _render(tester, 'icon_foreground.png', null, AuraColors.accent, 0.44);
    // Android 13's themed icons tint a one-colour version.
    await _render(tester, 'icon_monochrome.png', null, Colors.white, 0.44);
  });
}

/// Writes a 1024 px square: the ring, [share] of the square wide, in [ink]
/// on [background] (or on nothing).
Future<void> _render(
  WidgetTester tester,
  String name,
  Color? background,
  Color ink,
  double share,
) async {
  const size = 1024.0;
  tester.view.physicalSize = const Size.square(size);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: CustomPaint(
        size: const Size.square(size),
        painter: _RingIcon(background: background, ink: ink, share: share),
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
  File('$_out/$name')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!);
}

class _RingIcon extends CustomPainter {
  const _RingIcon({
    required this.background,
    required this.ink,
    required this.share,
  });

  final Color? background;
  final Color ink;
  final double share;

  @override
  void paint(Canvas canvas, Size size) {
    if (background case final background?) {
      canvas.drawRect(Offset.zero & size, Paint()..color = background);
    }
    final center = size.center(Offset.zero);
    final diameter = size.width * share;
    final stroke = diameter * 0.2;
    final rect = Rect.fromCircle(
      center: center,
      radius: (diameter - stroke) / 2,
    );
    // The track, faint, then the ring three quarters of the way round from
    // the top, as Today draws a day that's going well.
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = ink.withValues(alpha: 0.18),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * 0.75,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(_RingIcon old) => false;
}
