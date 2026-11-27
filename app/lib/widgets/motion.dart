import 'package:flutter/material.dart';

// The motion the whole app shares. All of it stands still when the phone
// asks for less motion, and none of it repeats for ever, so screens settle.

/// Whether the phone asks for less motion.
bool motionOff(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Shrinks a little under the finger, so a tap feels like a press. It only
/// listens, so taps still reach the button or card inside.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || motionOff(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Rises and fades into place the first time it's built. The [index]-th
/// item starts a [step] later than the one before, so a screen's cards
/// arrive one after another, and cards further down rise as they're
/// scrolled to.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 60),
    this.maxIndex = 6,
    this.rise = 24,
    this.grow = false,
  });

  final int index;
  final Widget child;
  final Duration step;

  /// Items past this one don't wait any longer.
  final int maxIndex;

  /// How far below its place it starts, in pixels.
  final double rise;

  /// Also grows from smaller, like a calendar day popping in.
  final bool grow;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  static const _length = Duration(milliseconds: 420);

  late final Duration _wait =
      widget.step * widget.index.clamp(0, widget.maxIndex);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _wait + _length,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _wait.inMicroseconds / (_wait + _length).inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (motionOff(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final t = _t.value;
        if (t >= 1) return child!;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.rise),
            child: widget.grow
                ? Transform.scale(scale: 0.7 + 0.3 * t, child: child)
                : child,
          ),
        );
      },
    );
  }
}

/// A number that counts to [value]: from zero the first time when
/// [fromZero], and from where it was whenever it changes.
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.fromZero = true,
    this.maxLines,
    this.softWrap,
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final bool fromZero;
  final int? maxLines;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    Text text(double v) =>
        Text(format(v), style: style, maxLines: maxLines, softWrap: softWrap);
    if (motionOff(context)) return text(value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: fromZero ? 0 : value, end: value),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => text(v),
    );
  }
}

/// A fraction from 0 to 1 that fills to [value], from empty the first time:
/// rings and bars. [child] is passed through, unbuilt again.
class FillUp extends StatelessWidget {
  const FillUp({
    super.key,
    required this.value,
    required this.builder,
    this.child,
  });

  final double value;
  final Widget Function(BuildContext context, double value, Widget? child)
  builder;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (motionOff(context)) return builder(context, value, child);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: builder,
      child: child,
    );
  }
}

/// A screen's cards with a [gap] between them, each rising in after the one
/// before.
List<Widget> staggered(List<Widget> children, {double gap = 12}) => [
  for (final (index, child) in children.indexed)
    Padding(
      padding: EdgeInsets.only(top: index == 0 ? 0 : gap),
      child: Entrance(index: index, child: child),
    ),
];
