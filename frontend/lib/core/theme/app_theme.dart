import 'package:flutter/material.dart';

import 'package:goal_getter/core/theme/app_dimens.dart';
import 'package:goal_getter/core/theme/app_palette.dart';

/// 1. CUSTOM SEMANTIC TOKENS (Tailwind-like custom design tokens)
///
/// Read with [CustomColors.of]. Both themes carry the extension, so the lookup
/// cannot miss; a `?? fallback` could only ever paint the dark theme with a
/// light-mode colour, and `tool/frontend_linter.dart` refuses the nullable
/// lookup outside this directory (#227).
class CustomColors extends ThemeExtension<CustomColors> {
  final Color success; // elo gained (green)
  final Color lost; // elo lost (blue)
  final Color errorMuted;
  final Color accentMuted;

  const CustomColors({
    required this.success,
    required this.lost,
    required this.errorMuted,
    required this.accentMuted,
  });

  /// The semantic colours of the theme around [context].
  static CustomColors of(BuildContext context) =>
      Theme.of(context).extension<CustomColors>()!;

  @override
  CustomColors copyWith({
    Color? success,
    Color? lost,
    Color? errorMuted,
    Color? accentMuted,
  }) {
    return CustomColors(
      success: success ?? this.success,
      lost: lost ?? this.lost,
      errorMuted: errorMuted ?? this.errorMuted,
      accentMuted: accentMuted ?? this.accentMuted,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      success: Color.lerp(success, other.success, t)!,
      lost: Color.lerp(lost, other.lost, t)!,
      errorMuted: Color.lerp(errorMuted, other.errorMuted, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
    );
  }
}

/// 2. THE MAIN THEME CONFIGURATION
///
/// Radius and spacing live next door in `app_dimens.dart`, and colours in
/// `app_palette.dart`; this file spends them. Nothing outside `lib/core/theme/`
/// may write a colour, a font size, a radius or a padding as a literal —
/// `tool/frontend_linter.dart` enforces it.
///
/// [light] and [dark] are one builder over two palettes, so the modes differ
/// in colour only (#178).
class AppTheme {
  AppTheme._();

  // --- Colours a screen may name directly ---
  // The colour scheme covers everything a layout decides for itself. These
  // three are the exceptions: a foreign brand colour, and two values that are
  // not really colours at all.

  /// Google's brand blue, for the sign-in button that has to wear it.
  static const googleBlue = Color(0xFF4285F4);

  /// The scrim over an image or behind a sheet.
  static const scrim = Colors.black;

  /// "No fill", for a Material whose child paints its own background.
  static const transparent = Colors.transparent;

  // --- Type scale ---
  static const double _fontSize10 = 10;
  static const double _fontSize12 = 12;
  static const double _fontSize14 = 14;
  static const double _fontSize16 = 16;
  static const double _fontSize18 = 18;
  static const double _fontSize20 = 20;
  static const double _fontSize24 = 24;
  static const double _fontSize32 = 32;
  static const String _fontFamily = 'Roboto';

  static ColorScheme _colorScheme(AppPalette p) => _baseScheme(p).copyWith(
    primary: p.primary,
    onPrimary: AppPalette.onFill,
    primaryContainer: p.primaryContainer,
    secondary: p.secondary,
    onSecondary: AppPalette.onFill,
    surface: p.surface,
    surfaceContainer: p.surfaceMuted, // card / chip fill
    surfaceContainerHigh: p.surfaceMutedHigh, // inputs / nav
    onSurface: p.ink, // primary text
    onSurfaceVariant: p.muted, // secondary / muted text
    outline: p.hairline, // borders & dividers
    error: p.error,
    onError: AppPalette.onFill,
  );

  /// Material's own scheme for [p]'s brightness: the roles the palette
  /// leaves unset (containers, tertiary, inverse) come from here.
  static ColorScheme _baseScheme(AppPalette p) =>
      p.brightness == Brightness.dark
          ? const ColorScheme.dark()
          : const ColorScheme.light();

  static TextStyle _style(
    double size,
    Color color, {
    FontWeight? weight,
    double? height,
  }) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  /// --- Global Typography System ---
  ///
  /// Every piece of text in the app picks one of these and, at most,
  /// `copyWith`s a colour or a weight onto it.
  static TextTheme _textTheme(AppPalette p) => TextTheme(
    bodyLarge: _style(_fontSize16, p.body, height: 1.5),
    bodyMedium: _style(_fontSize14, p.body, height: 1.5),
    bodySmall: _style(_fontSize12, p.body, height: 1.4),
    titleLarge: _style(
      _fontSize20,
      p.ink,
      weight: FontWeight.w700,
      height: 1.3,
    ),
    titleMedium: _style(
      _fontSize18,
      p.ink,
      weight: FontWeight.w600,
      height: 1.3,
    ),
    titleSmall: _style(
      _fontSize16,
      p.ink,
      weight: FontWeight.w600,
      height: 1.3,
    ),
    labelLarge: _style(_fontSize14, p.ink, weight: FontWeight.w600),
    labelMedium: _style(_fontSize12, p.muted, weight: FontWeight.w500),
    headlineSmall: _style(
      _fontSize20,
      p.ink,
      weight: FontWeight.bold,
      height: 1.3,
    ),
    // The label on a full-width primary action, and the single letter in an
    // avatar: the biggest type that is not a screen title.
    headlineLarge: _style(_fontSize24, p.ink, weight: FontWeight.bold),
    headlineMedium: _style(_fontSize32, p.ink, weight: FontWeight.bold),
  );

  /// Lovable-style cards: the page's surface with a 1px hairline border, no
  /// shadow.
  static CardThemeData _cardTheme(AppPalette p) => CardThemeData(
    color: p.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.cardBorder,
      side: BorderSide(color: p.hairline),
    ),
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
  );

  static InputDecorationTheme _inputTheme(
    AppPalette p,
    ColorScheme colorScheme,
  ) => InputDecorationTheme(
    filled: true,
    fillColor: colorScheme.surfaceContainer,
    hintStyle: TextStyle(color: p.muted, fontSize: _fontSize14),
    border: OutlineInputBorder(
      borderRadius: AppRadius.cardBorder,
      borderSide: BorderSide(color: p.hairline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.cardBorder,
      borderSide: BorderSide(color: p.hairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.cardBorder,
      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
  );

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colorScheme) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.cardBorder,
          ),
        ),
      );

  static ThemeData get light => _build(AppPalette.light);

  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final colorScheme = _colorScheme(p);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      extensions: [
        CustomColors(
          success: p.success,
          lost: p.lost,
          errorMuted: p.errorMuted,
          accentMuted: p.accentMuted,
        ),
      ],

      textTheme: _textTheme(p),

      // --- Component Themes ---
      cardTheme: _cardTheme(p),
      inputDecorationTheme: _inputTheme(p, colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        // Font size only: the bar takes the rest from its own defaults, as it
        // did when this was the widget's `selectedFontSize: 10`.
        selectedLabelStyle: const TextStyle(fontSize: _fontSize10),
        unselectedLabelStyle: const TextStyle(fontSize: _fontSize10),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),

      dividerTheme: DividerThemeData(color: p.hairline, thickness: 1),
    );
  }
}
