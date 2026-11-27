import 'package:flutter/painting.dart';

/// Type that isn't in the Material scale: the big condensed capitals for
/// headings and numbers. Everything else is DM Sans, set in the theme.
abstract final class AuraType {
  /// Barlow Condensed ExtraBold, for short headings written in capitals.
  /// [size] follows the phone's font size setting like any other text.
  static TextStyle display(double size, {Color? color}) => TextStyle(
    fontFamily: 'BarlowCondensed',
    fontWeight: FontWeight.w800,
    fontSize: size,
    height: 0.95,
    color: color,
  );

  /// The small spaced capitals above a card's heading, like "PROTEIN".
  static TextStyle kicker({Color? color}) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: color,
  );
}
