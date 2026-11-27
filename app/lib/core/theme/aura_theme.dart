import 'package:aurafit/core/theme/aura_colors.dart';
import 'package:flutter/material.dart';

/// The app's one theme: the trainer design's dark look, with bright cards,
/// pill buttons and rounded filled fields.
///
/// Text is DM Sans, bundled, so the app looks the same on every phone (some
/// phones' own font is a serif), and headlines are Barlow Condensed like the
/// cards. Every text style here starts from the type scale, never a bare
/// TextStyle, or it would fall back to the phone's font. Sizes follow the
/// phone's font size setting.
ThemeData buildAuraTheme() {
  const fieldRadius = BorderRadius.all(Radius.circular(18));
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

  OutlineInputBorder outline(Color? color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: color == null
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );

  // From the type scale, so buttons keep the theme's font.
  final buttonText = base.textTheme.labelLarge?.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Headlines in the cards' condensed font.
  TextStyle? condensed(TextStyle? style) => style?.copyWith(
    fontFamily: 'BarlowCondensed',
    fontWeight: FontWeight.w800,
    height: 1.05,
  );
  final textTheme = base.textTheme
      .copyWith(
        displayLarge: condensed(base.textTheme.displayLarge),
        displayMedium: condensed(base.textTheme.displayMedium),
        displaySmall: condensed(base.textTheme.displaySmall),
        headlineLarge: condensed(base.textTheme.headlineLarge),
        headlineMedium: condensed(base.textTheme.headlineMedium),
        headlineSmall: condensed(base.textTheme.headlineSmall)
            ?.copyWith(fontSize: 30),
      )
      .apply(
        bodyColor: AuraColors.foreground,
        displayColor: AuraColors.foreground,
      );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AuraColors.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        fontSize: 28,
        color: AuraColors.foreground,
      ),
    ),
    // Every screen slides and fades in the same modern way.
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: buttonText?.copyWith(fontWeight: FontWeight.w700),
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
    // The second choice: a dark pill, like the design's secondary buttons.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AuraColors.foreground,
        backgroundColor: AuraColors.surface,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AuraColors.surfaceStrong, width: 1.5),
        shape: const StadiumBorder(),
        textStyle: buttonText,
      ),
    ),
    // Filled and borderless until focused, like the design's fields.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AuraColors.surface,
      border: outline(null),
      enabledBorder: outline(null),
      focusedBorder: outline(AuraColors.accent, width: 2),
      errorBorder: outline(AuraColors.error),
      focusedErrorBorder: outline(AuraColors.error, width: 2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: base.textTheme.bodyLarge?.copyWith(color: AuraColors.muted),
      floatingLabelStyle: base.textTheme.bodyLarge?.copyWith(
        color: AuraColors.accentSoft,
      ),
      hintStyle: base.textTheme.bodyLarge?.copyWith(color: AuraColors.faint),
      suffixStyle: base.textTheme.bodyLarge?.copyWith(color: AuraColors.muted),
      prefixIconColor: AuraColors.muted,
      suffixIconColor: AuraColors.muted,
    ),
    cardTheme: const CardThemeData(
      color: AuraColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AuraColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        fontSize: 26,
        color: AuraColors.foreground,
      ),
      contentTextStyle: textTheme.bodyLarge?.copyWith(color: AuraColors.muted),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AuraColors.accent
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(AuraColors.ink),
      side: const BorderSide(color: AuraColors.muted, width: 2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AuraColors.ink
            : AuraColors.muted,
      ),
      trackColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AuraColors.accent
            : AuraColors.surfaceStrong,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(color: AuraColors.surfaceStrong),
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
      dragHandleColor: AuraColors.faint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AuraColors.accent,
      linearTrackColor: AuraColors.surfaceStrong,
    ),
    // In paper, so it stands out over the dark cards. The text style comes
    // from the type scale: a bare TextStyle showed in the phone's own font.
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AuraColors.paper,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AuraColors.ink,
        fontWeight: FontWeight.w600,
      ),
      actionTextColor: const Color(0xFFB34700),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    ),
  );
}
