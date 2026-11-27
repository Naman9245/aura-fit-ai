import 'package:flutter/painting.dart';

/// The trainer design's dark look: a soft near-black with bright cards.
///
/// Text colours all pass WCAG AA on [black], [surface] and [surfaceStrong]:
/// [foreground] is 16:1 on [black], [muted] 9.2:1 on [black] and 7:1 on
/// [surfaceStrong], and [accent] 6.9:1 on [black]. Buttons put [black] text
/// on [accent], since white on orange would only reach 2.9:1.
abstract final class AuraColors {
  /// The background.
  static const black = Color(0xFF17151F);

  /// Cards, fields and sheets.
  static const surface = Color(0xFF24212E);

  /// Tiles inside a card, and progress tracks.
  static const surfaceStrong = Color(0xFF2F2B3B);

  /// Buttons, the selected tab and key numbers.
  static const accent = Color(0xFFFF7A00);

  /// Links and secondary highlights: 8.8:1 on [black].
  static const accentSoft = Color(0xFFFF9F43);

  /// Body text.
  static const foreground = Color(0xFFF4F1EA);

  /// Secondary text and field outlines.
  static const muted = Color(0xFFB9B4C7);

  /// Numbers that don't need reading, like days to come on the calendar:
  /// 5.7:1 on [black].
  static const faint = Color(0xFF948EA6);

  /// The faint edge of a card: white at 8%.
  static const border = Color(0x14FFFFFF);

  /// Field errors: 7.9:1 on [black].
  static const error = Color(0xFFFF8A80);

  // The bright cards. Text on any of them is [ink]: 9.95:1 on [sky], 6.5:1
  // on [lilac], 11.5:1 on [mint], 13:1 on [yellow] and 6.9:1 on [accent].

  /// Text and buttons on a bright card.
  static const ink = Color(0xFF17151F);

  /// Text on [ink]: 16:1.
  static const paper = Color(0xFFF4F1EA);

  /// The card behind Josh when it isn't dark: his fur stands out on it.
  static const sky = Color(0xFF8EC5FF);

  /// Lilac cards with no Josh on them.
  static const lilac = Color(0xFF9B8CFF);

  /// Lilac behind Josh: his fur gets lost on [lilac].
  static const lilacLight = Color(0xFFCDC4FF);

  static const mint = Color(0xFF7EE0C3);

  static const yellow = Color(0xFFFFD66B);
}
