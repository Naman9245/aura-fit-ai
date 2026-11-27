import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:flutter/material.dart';

/// The app's one theme: always dark, like the website.
///
/// Text is DM Sans, bundled, so the app looks the same on every phone (some
/// phones' own font is a serif). Sizes come from the Material type scale,
/// so they follow the phone's font size setting.
ThemeData buildAuraTheme() {
  const radius = BorderRadius.all(Radius.circular(16));
  const scheme = ColorScheme.dark(
    primary: AuraColors.accent,
    onPrimary: AuraColors.black,
    secondary: AuraColors.accentSoft,
    onSecondary: AuraColors.black,
    surface: AuraColors.black,
    onSurface: AuraColors.foreground,
    onSurfaceVariant: AuraColors.muted,
    surfaceContainerLowest: AuraColors.black,
    surfaceContainerLow: AuraColors.surface,
    surfaceContainer: AuraColors.surface,
    surfaceContainerHigh: AuraColors.surfaceStrong,
    surfaceContainerHighest: AuraColors.surfaceStrong,
    outline: AuraColors.muted,
    outlineVariant: AuraColors.border,
    error: AuraColors.error,
    onError: AuraColors.black,
  );
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'DMSans',
    colorScheme: scheme,
    scaffoldBackgroundColor: AuraColors.black,
  );

  OutlineInputBorder outline(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );

  // From the type scale, so buttons keep the theme's font.
  final buttonText = base.textTheme.labelLarge?.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AuraColors.foreground,
      displayColor: AuraColors.foreground,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AuraColors.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: const RoundedRectangleBorder(borderRadius: radius),
        textStyle: buttonText,
        disabledBackgroundColor: AuraColors.surfaceStrong,
        disabledForegroundColor: AuraColors.muted,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AuraColors.accentSoft,
        minimumSize: const Size(48, 48),
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AuraColors.foreground,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AuraColors.muted),
        shape: const RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AuraColors.surface,
      border: outline(AuraColors.muted),
      enabledBorder: outline(AuraColors.muted),
      focusedBorder: outline(AuraColors.accent, width: 2),
      errorBorder: outline(AuraColors.error),
      focusedErrorBorder: outline(AuraColors.error, width: 2),
      labelStyle: const TextStyle(color: AuraColors.muted),
      floatingLabelStyle: const TextStyle(color: AuraColors.accentSoft),
      suffixStyle: const TextStyle(color: AuraColors.muted),
    ),
    cardTheme: const CardThemeData(
      color: AuraColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        side: BorderSide(color: AuraColors.border),
      ),
    ),
    // Yesterday / Today: the chosen one in paper, like the design's chips.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: AuraColors.surface,
        foregroundColor: AuraColors.muted,
        selectedBackgroundColor: AuraColors.paper,
        selectedForegroundColor: AuraColors.ink,
        side: BorderSide.none,
        minimumSize: const Size(0, 44),
        textStyle: buttonText?.copyWith(fontSize: 14),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AuraColors.surface,
      selectedColor: AuraColors.paper,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: base.textTheme.labelLarge?.copyWith(
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AuraColors.ink
              : AuraColors.foreground,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AuraColors.surface,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AuraColors.accent,
      linearTrackColor: AuraColors.surfaceStrong,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AuraColors.surfaceStrong,
      contentTextStyle: TextStyle(color: AuraColors.foreground),
      actionTextColor: AuraColors.accentSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: AuraColors.border),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
