import 'dart:math' as math;

import 'package:flutter/material.dart';

/// How Josh feels. He is never sad or angry at the person using the app.
enum JoshMood {
  /// Hello, the intro, logging food.
  happy,

  /// A workout day: fire in his eyes, lifting a dumbbell.
  fired,

  /// Mid-set and during rest.
  sweaty,

  /// A lift beaten, a week done.
  proud,

  /// Rest days.
  sleepy,

  /// After a missed day: no guilt.
  calm,
}

/// How fit Josh looks. He gets fitter as the streak grows and never shrinks.
enum JoshStage {
  /// Day 1: a chubby cub.
  cub,

  /// Day 7.
  gettingGoing,

  /// Day 30: abs and bigger arms.
  fit,

  /// Day 60.
  beastMode;

  /// The stage for a streak of [days]: days the person stuck to their plan,
  /// rest days included.
  static JoshStage forStreak(int days) => switch (days) {
    >= 60 => beastMode,
    >= 30 => fit,
    >= 7 => gettingGoing,
    _ => cub,
  };
}

/// How long Josh moves when a tab opens, before he rests: see
/// [Josh.playFor].
const joshPlayFor = Duration(seconds: 8);

/// Josh, the AURA mascot: a bear cub with a mint sweatband and sneakers.
///
/// He moves (bobs, blinks, waves, and his eyes flicker when fired up) unless
/// the phone asks for less motion, and then he stands still.
class Josh extends StatefulWidget {
  const Josh({
    super.key,
    required this.mood,
    this.stage = JoshStage.cub,
    this.width = 200,
    this.playFor,
    this.wakeKey,
  });

  final JoshMood mood;
  final JoshStage stage;

  /// His height follows: 1.15 times the width.
  final double width;

  /// On screens people stay on, like Today: he moves for this long, then
  /// holds still until he's tapped or his mood or stage changes, so he
  /// doesn't keep the phone busy. Null: he moves for as long as he's on
  /// screen, as in the intro.
  final Duration? playFor;

  /// When this changes, he moves again: something was just logged.
  final Object? wakeKey;

  @override
  State<Josh> createState() => _JoshState();
}

class _JoshState extends State<Josh> with SingleTickerProviderStateMixin {
  // A long loop, so every movement's own period fits many times over.
  static const _loop = Duration(seconds: 60);

  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: _loop,
  );
  bool _still = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still) {
      _started = false;
      _clock
        ..stop()
        ..value = 0;
    } else if (!_started) {
      _started = true;
      _play();
    }
  }

  @override
  void didUpdateWidget(Josh old) {
    super.didUpdateWidget(old);
    if (_still) return;
    if (old.mood != widget.mood ||
        old.stage != widget.stage ||
        old.wakeKey != widget.wakeKey) {
      _play();
    }
  }

  /// Moves on from where he stands, so he never jumps.
  void _play() {
    final playFor = widget.playFor;
    if (playFor == null) {
      _clock.repeat();
      return;
    }
    final share = playFor.inMilliseconds / _loop.inMilliseconds;
    var to = _clock.value + share;
    if (to > 1) {
      _clock.value = 0;
      to = share;
    }
    _clock.animateTo(to, duration: playFor);
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawn = Semantics(
      image: true,
      label: joshLabel(widget.mood, widget.stage),
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) => CustomPaint(
              size: Size(widget.width, widget.width * 1.15),
              painter: JoshPainter(
                mood: widget.mood,
                stage: widget.stage,
                seconds: _clock.value * _loop.inMilliseconds / 1000,
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.playFor == null) return drawn;
    // A tap wakes him up again; it's only for fun, so screen readers skip it.
    return GestureDetector(
      excludeFromSemantics: true,
      onTap: () {
        if (!_still && !_clock.isAnimating) _play();
      },
      child: drawn,
    );
  }
}

/// What a screen reader says for Josh.
String joshLabel(JoshMood mood, JoshStage stage) {
  final looks = switch (stage) {
    JoshStage.cub => 'a cub',
    JoshStage.gettingGoing => 'getting going',
    JoshStage.fit => 'fit',
    JoshStage.beastMode => 'in beast mode',
  };
  final doing = switch (mood) {
    JoshMood.happy => 'waving hello',
    JoshMood.fired => 'with fire in his eyes, lifting a dumbbell',
    JoshMood.sweaty => 'working hard mid-set',
    JoshMood.proud => 'proud of a new best',
    JoshMood.sleepy => 'asleep on a rest day',
    JoshMood.calm => 'calm',
  };
  return 'Josh the bear, $looks, $doing';
}

/// Draws Josh on a 200 by 230 grid, scaled to fit, at [seconds] into his
/// animations (0 = at rest).
class JoshPainter extends CustomPainter {
  JoshPainter({required this.mood, required this.stage, this.seconds = 0});

  final JoshMood mood;
  final JoshStage stage;
  final double seconds;

  static const _fur = Color(0xFFC47A3D);
  static const _furDark = Color(0xFFB06A30);
  static const _cream = Color(0xFFF4D6AE);
  static const _crease = Color(0xFFD9A66B);
  static const _dark = Color(0xFF2A1E18);
  static const _pink = Color(0xFFFFB8C6);
  static const _blush = Color(0xFFFF8FA3);
  static const _band = Color(0xFF7EE0C3);
  static const _bandTail = Color(0xFF4FBF9F);
  static const _shoe = Color(0xFFFFF6E6);
  // The dumbbell shows on light cards and on dark ones.
  static const _bar = Color(0xFF8F89A3);
  static const _plate = Color(0xFFFF7A00);
  static const _flameOuter = Color(0xFFFF7A00);
  static const _flameCore = Color(0xFFFFD23F);
  static const _sweat = Color(0xFF4DB3FF);
  // Shows on light cards and on dark ones.
  static const _sleepZ = Color(0xFF8F7DFF);

  /// 0 to 1 and back over [period] seconds, smoothly.
  double _wave(double period, [double delay = 0]) =>
      0.5 - 0.5 * math.cos(2 * math.pi * ((seconds - delay) / period));

  /// 0 to 1 over [period] seconds, then again.
  double _saw(double period, [double delay = 0]) {
    final t = (seconds - delay) / period;
    return t - t.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 200, size.height / 230);
    canvas
      ..save()
      ..translate(
        (size.width - 200 * scale) / 2,
        (size.height - 230 * scale) / 2,
      )
      ..scale(scale);

    _oval(canvas, const Offset(100, 222), 54, 6, const Color(0x33000000));
    canvas
      ..save()
      ..translate(0, -6 * _wave(2.4));
    _body(canvas);
    _head(canvas);
    _face(canvas);
    canvas
      ..restore()
      ..restore();
  }

  void _body(Canvas canvas) {
    // Legs and sneakers.
    for (final x in [72.0, 108.0]) {
      _rrect(canvas, Rect.fromLTWH(x, 188, 20, 20), 8, _furDark);
    }
    for (final x in [64.0, 104.0]) {
      _rrect(canvas, Rect.fromLTWH(x, 202, 32, 16), 8, _shoe);
      _line(canvas, Offset(x, 211), Offset(x + 32, 211), _bandTail, 3);
    }

    switch (stage) {
      case JoshStage.cub:
        _oval(canvas, const Offset(100, 168), 50, 42, _fur);
        _oval(canvas, const Offset(100, 174), 34, 30, _cream);
      case JoshStage.gettingGoing:
        _oval(canvas, const Offset(100, 168), 46, 41, _fur);
        _oval(canvas, const Offset(100, 172), 29, 28, _cream);
      case JoshStage.fit:
        _fill(
          canvas,
          _quads(const Offset(54, 140), const [
            [100, 126, 146, 140],
            [152, 176, 132, 206],
            [100, 214, 68, 206],
            [48, 176, 54, 140],
          ]),
          _fur,
        );
        _fill(
          canvas,
          _quads(const Offset(76, 150), const [
            [100, 142, 124, 150],
            [126, 180, 114, 200],
            [100, 204, 86, 200],
            [74, 180, 76, 150],
          ]),
          _cream,
        );
        _line(
          canvas,
          const Offset(100, 160),
          const Offset(100, 196),
          _crease,
          2.5,
        );
        _line(
          canvas,
          const Offset(86, 172),
          const Offset(114, 172),
          _crease,
          2.5,
        );
        _line(
          canvas,
          const Offset(88, 186),
          const Offset(112, 186),
          _crease,
          2.5,
        );
      case JoshStage.beastMode:
        _fill(
          canvas,
          _quads(const Offset(44, 138), const [
            [100, 118, 156, 138],
            [162, 178, 136, 208],
            [100, 216, 64, 208],
            [38, 178, 44, 138],
          ]),
          _fur,
        );
        _fill(
          canvas,
          _quads(const Offset(70, 148), const [
            [100, 136, 130, 148],
            [132, 182, 116, 202],
            [100, 206, 84, 202],
            [68, 182, 70, 148],
          ]),
          _cream,
        );
        _stroke(
          canvas,
          _quads(const Offset(78, 160), const [
            [90, 168, 100, 160],
            [110, 168, 122, 160],
          ]),
          _crease,
          2.5,
        );
        _line(
          canvas,
          const Offset(100, 166),
          const Offset(100, 198),
          _crease,
          2.5,
        );
        _line(
          canvas,
          const Offset(86, 176),
          const Offset(114, 176),
          _crease,
          2.5,
        );
        _line(
          canvas,
          const Offset(88, 188),
          const Offset(112, 188),
          _crease,
          2.5,
        );
    }

    // Arms: wider shoulders and thicker arms at each stage.
    final i = stage.index;
    final sx = const [58.0, 56.0, 52.0, 46.0][i];
    final sy = const [150.0, 148.0, 146.0, 144.0][i];
    final w = const [14.0, 16.0, 19.0, 23.0][i];
    final rx = 200 - sx;
    _line(canvas, Offset(sx, sy), Offset(sx - 18, sy + 28), _fur, w);

    switch (mood) {
      case JoshMood.happy:
        final pivot = Offset(rx, sy - 4);
        canvas
          ..save()
          ..translate(pivot.dx, pivot.dy)
          ..rotate(-28 * math.pi / 180 * _wave(1.1))
          ..translate(-pivot.dx, -pivot.dy);
        _line(canvas, pivot, Offset(rx + 24, sy - 36), _fur, w);
        canvas.restore();
      case JoshMood.fired || JoshMood.proud:
        final fist = Offset(rx + 26, sy - 38);
        _stroke(
          canvas,
          Path()
            ..moveTo(rx, sy)
            ..quadraticBezierTo(rx + 30, sy - 2, fist.dx, fist.dy + 8),
          _fur,
          w,
        );
        if (stage.index >= JoshStage.fit.index) {
          _circle(
            canvas,
            Offset(rx + 18, sy - 10),
            stage == JoshStage.beastMode ? 13 : 10,
            _fur,
          );
        }
        canvas
          ..save()
          ..translate(fist.dx, fist.dy - 8 * _wave(1.2));
        _line(canvas, const Offset(-18, -14), const Offset(10, -14), _bar, 5);
        _rrect(canvas, const Rect.fromLTWH(-24, -24, 8, 20), 3, _plate);
        _rrect(canvas, const Rect.fromLTWH(8, -24, 8, 20), 3, _plate);
        canvas.restore();
        _circle(canvas, fist, (w * 0.75).roundToDouble(), _fur);
      case JoshMood.sweaty || JoshMood.sleepy || JoshMood.calm:
        _line(canvas, Offset(rx, sy), Offset(rx + 18, sy + 28), _fur, w);
    }
  }

  void _head(Canvas canvas) {
    for (final x in [58.0, 142.0]) {
      _circle(canvas, Offset(x, 58), 17, _fur);
      _circle(canvas, Offset(x, 58), 9, _pink);
    }
    _circle(canvas, const Offset(100, 96), 50, _fur);
    _fill(
      canvas,
      _poly(const [Offset(146, 84), Offset(166, 76), Offset(162, 92)]),
      _bandTail,
    );
    _fill(
      canvas,
      _poly(const [Offset(146, 88), Offset(164, 98), Offset(152, 102)]),
      _bandTail,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(52, 80)
        ..quadraticBezierTo(100, 62, 148, 80)
        ..lineTo(148, 92)
        ..quadraticBezierTo(100, 76, 52, 92)
        ..close(),
      _band,
    );
    _oval(canvas, const Offset(100, 116), 24, 17, _cream);
    _oval(canvas, const Offset(100, 108), 8, 5.5, _dark);
    _oval(canvas, const Offset(97, 106.5), 2.5, 1.4, const Color(0x99FFFFFF));
  }

  void _face(Canvas canvas) {
    switch (mood) {
      case JoshMood.happy || JoshMood.sweaty || JoshMood.calm:
        _roundEyes(canvas);
      case JoshMood.fired:
        for (final dx in [0.0, 40.0]) {
          _flame(canvas, dx);
        }
        _line(canvas, const Offset(66, 80), const Offset(90, 86), _dark, 5);
        _line(canvas, const Offset(134, 80), const Offset(110, 86), _dark, 5);
      case JoshMood.sleepy:
        for (final x in [72.0, 112.0]) {
          _stroke(
            canvas,
            Path()
              ..moveTo(x, 95)
              ..quadraticBezierTo(x + 8, 101, x + 16, 95),
            _dark,
            4,
          );
        }
      case JoshMood.proud:
        for (final x in [72.0, 112.0]) {
          _stroke(
            canvas,
            Path()
              ..moveTo(x, 98)
              ..quadraticBezierTo(x + 8, 88, x + 16, 98),
            _dark,
            4.5,
          );
        }
    }

    if (mood == JoshMood.happy ||
        mood == JoshMood.proud ||
        mood == JoshMood.calm) {
      _oval(
        canvas,
        const Offset(66, 110),
        8,
        5,
        _blush.withValues(alpha: 0.85),
      );
      _oval(
        canvas,
        const Offset(134, 110),
        8,
        5,
        _blush.withValues(alpha: 0.85),
      );
    }

    switch (mood) {
      case JoshMood.happy || JoshMood.calm:
        _line(canvas, const Offset(100, 113), const Offset(100, 117), _dark, 3);
        _stroke(
          canvas,
          Path()
            ..moveTo(90, 117)
            ..quadraticBezierTo(95, 123, 100, 117)
            ..quadraticBezierTo(105, 123, 110, 117),
          _dark,
          3,
        );
      case JoshMood.fired || JoshMood.proud:
        _fill(
          canvas,
          Path()
            ..moveTo(89, 115)
            ..quadraticBezierTo(100, 134, 111, 115)
            ..close(),
          _dark,
        );
        _fill(
          canvas,
          Path()
            ..moveTo(95, 124)
            ..quadraticBezierTo(100, 130, 105, 124)
            ..quadraticBezierTo(100, 121, 95, 124)
            ..close(),
          _blush,
        );
      case JoshMood.sweaty:
        _oval(canvas, const Offset(100, 121), 4.5, 5.5, _dark);
        final fall = _saw(1.6);
        canvas
          ..save()
          ..translate(0, 16 * fall);
        _fill(
          canvas,
          Path()
            ..moveTo(156, 84)
            ..cubicTo(161, 92, 163, 97, 156, 100)
            ..cubicTo(149, 97, 151, 92, 156, 84)
            ..close(),
          _sweat.withValues(alpha: 1 - fall),
        );
        canvas.restore();
      case JoshMood.sleepy:
        _stroke(
          canvas,
          Path()
            ..moveTo(94, 119)
            ..quadraticBezierTo(100, 122, 106, 119),
          _dark,
          3,
        );
        // Phased so both show when he stands still.
        _z(canvas, const Offset(148, 58), 26, -0.8);
        _z(canvas, const Offset(166, 42), 18, -1.6);
    }
  }

  void _roundEyes(Canvas canvas) {
    // A blink every 4.2 seconds, squashing both eyes about their middle.
    final p = _saw(4.2);
    final squash = p < 0.9
        ? 1.0
        : p < 0.94
        ? 1 - (p - 0.9) / 0.04 * 0.92
        : 0.08 + (p - 0.94) / 0.06 * 0.92;
    canvas
      ..save()
      ..translate(0, 95)
      ..scale(1, squash)
      ..translate(0, -95);
    for (final x in [80.0, 120.0]) {
      _oval(canvas, Offset(x, 95), 8, 9, _dark);
      _circle(canvas, Offset(x + 3, 91), 3, Colors.white);
      _circle(canvas, Offset(x - 2.5, 98.5), 1.3, Colors.white);
    }
    canvas.restore();
  }

  void _flame(Canvas canvas, double dx) {
    final t = _wave(0.45);
    final grow = 1 + 0.18 * t;
    final tilt = (-4 + 8 * t) * math.pi / 180;
    void draw(Path path, Offset base, Color color) {
      canvas
        ..save()
        ..translate(base.dx + dx, base.dy)
        ..rotate(tilt)
        ..scale(grow)
        ..translate(-base.dx - dx, -base.dy);
      _fill(canvas, path.shift(Offset(dx, 0)), color);
      canvas.restore();
    }

    draw(
      Path()
        ..moveTo(80, 80)
        ..cubicTo(87, 87, 89, 95, 86, 101)
        ..cubicTo(84, 105, 77, 105, 75, 101)
        ..cubicTo(72, 95, 74, 89, 78, 85)
        ..cubicTo(78, 90, 80, 91, 81, 89)
        ..cubicTo(82, 86, 81, 83, 80, 80)
        ..close(),
      const Offset(80.5, 104),
      _flameOuter,
    );
    draw(
      Path()
        ..moveTo(80, 90)
        ..cubicTo(83, 93, 84, 97, 82, 100)
        ..cubicTo(81, 102, 79, 102, 78, 100)
        ..cubicTo(77, 97, 78, 94, 80, 90)
        ..close(),
      const Offset(80, 101.5),
      _flameCore,
    );
  }

  void _z(Canvas canvas, Offset at, double size, double delay) {
    final p = _saw(2.6, delay);
    final opacity = p < 0.3 ? p / 0.3 : 1 - (p - 0.3) / 0.7;
    final painter = TextPainter(
      text: TextSpan(
        text: 'z',
        style: TextStyle(
          fontFamily: 'BarlowCondensed',
          fontWeight: FontWeight.w800,
          fontSize: size,
          color: _sleepZ.withValues(alpha: opacity.clamp(0, 1)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      at + Offset(8 * p, -16 * p) - Offset(0, painter.height * 0.8),
    );
  }

  // Drawing helpers.

  static Path _quads(Offset start, List<List<double>> segments) {
    final path = Path()..moveTo(start.dx, start.dy);
    for (final s in segments) {
      path.quadraticBezierTo(s[0], s[1], s[2], s[3]);
    }
    return path..close();
  }

  static Path _poly(List<Offset> points) => Path()..addPolygon(points, true);

  static void _fill(Canvas canvas, Path path, Color color) =>
      canvas.drawPath(path, Paint()..color = color);

  static void _stroke(Canvas canvas, Path path, Color color, double width) =>
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

  static void _line(
    Canvas canvas,
    Offset a,
    Offset b,
    Color color,
    double width,
  ) => canvas.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );

  static void _oval(
    Canvas canvas,
    Offset c,
    double rx,
    double ry,
    Color color,
  ) => canvas.drawOval(
    Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
    Paint()..color = color,
  );

  static void _circle(Canvas canvas, Offset c, double r, Color color) =>
      canvas.drawCircle(c, r, Paint()..color = color);

  static void _rrect(Canvas canvas, Rect rect, double r, Color color) =>
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(r)),
        Paint()..color = color,
      );

  @override
  bool shouldRepaint(JoshPainter old) =>
      old.mood != mood || old.stage != stage || old.seconds != seconds;
}
