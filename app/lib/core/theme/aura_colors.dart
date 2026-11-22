import 'package:flutter/painting.dart';

/// The website's dark look (frontend/src/app/globals.css), as colours.
///
/// Text colours all pass WCAG AA on [black] and [surfaceStrong]: [muted] is
/// 7.2:1 on [black], and [accent] is 7.6:1. Buttons put [black] text on
/// [accent], since white on orange would only reach 2.9:1.
abstract final class AuraColors {
  /// The background (--aura-black).
  static const black = Color(0xFF050816);

  /// Cards and fields (--aura-surface).
  static const surface = Color(0xFF0B1120);

  /// Raised cards and the progress track (--aura-surface-strong).
  static const surfaceStrong = Color(0xFF101A2B);

  /// Buttons, the selected choice and key numbers (--aura-accent).
  static const accent = Color(0xFFFF7A00);

  /// Links and secondary highlights (--aura-accent-soft).
  static const accentSoft = Color(0xFFFF9F43);

  /// Body text (--aura-foreground).
  static const foreground = Color(0xFFE7E9F4);

  /// Secondary text and field outlines (--aura-muted).
  static const muted = Color(0xFF8B93B3);

  /// The faint edge of a card (--aura-glass-border: white at 8%).
  static const border = Color(0x14FFFFFF);

  /// The two glows behind every screen.
  static const orangeGlow = Color(0x1FFF7A00);
  static const blueGlow = Color(0x2E587AFF);

  /// Field errors: 8.7:1 on [black].
  static const error = Color(0xFFFF8A80);
}
