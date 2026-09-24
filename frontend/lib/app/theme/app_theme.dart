import 'package:flutter/material.dart';

import 'app_dimens.dart';

/// 1. CUSTOM SEMANTIC TOKENS (Tailwind-like custom design tokens)
/// Retrieve via `Theme.of(context).extension<CustomColors>()!.success`
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? success; // elo gained (green)
  final Color? lost; // elo lost (blue)
  final Color? errorMuted;
  final Color? accentMuted;

  const CustomColors({
    this.success,
    this.lost,
    this.errorMuted,
    this.accentMuted,
  });

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
      success: Color.lerp(success, other.success, t),
      lost: Color.lerp(lost, other.lost, t),
      errorMuted: Color.lerp(errorMuted, other.errorMuted, t),
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t),
    );
  }
}

/// 2. THE MAIN THEME CONFIGURATION
///
/// Radius and spacing live next door in `app_dimens.dart`; this file spends
/// them. Nothing outside `lib/app/theme/` may write a colour, a font size, a
/// radius or a padding as a literal — `tool/frontend_linter.dart` enforces it.
class AppTheme {
  AppTheme._();

  // --- Primitive Color Tokens (light) ---
  static const _ink = Color(0xFF1A1A1A); // primary text / near-black
  static const _slateText = Color(0xFF6B7280); // secondary / muted text
  static const _hairline = Color(0xFFE5E7EB); // borders & dividers
  static const _surface = Colors.white;
  static const _surfaceMuted = Color(0xFFF5F5F7); // chip / filled background
  static const _surfaceMutedHigh = Color(0xFFEDEDF0);

  static const _green = Color(0xFF2D9D78); // primary accent (kept)
  static const _greenSuccess = Color(0xFF16A34A); // elo gained badge
  static const _orange = Color(0xFFF1820A); // streak flame
  static const _blue = Color(0xFF2563EB); // elo lost badge
  static const _red = Color(0xFFDC2626); // destructive / logout

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

  /// The start screen's backdrop — the one dark surface in a light app.
  static const startGradientTop = Color(0xFF212121);
  static const startGradientBottom = Color(0xFF0B0B0B);

  // The two foregrounds that backdrop needs, mirroring `_ink` and
  // `_slateText` on the other side of the contrast.
  static const _onDark = Colors.white;
  static const _onDarkMuted = Color(0xFFBDBDBD);

  /// The three semantic colours [CustomColors] carries, as plain constants.
  /// They exist for the two callers that cannot reach a [BuildContext]'s
  /// theme: the dev fixtures, and the `??` fallback on an extension lookup.
  static const success = _greenSuccess;
  static const lost = _blue;
  static const streak = _orange;

  // --- Type scale ---
  static const double _fontSize12 = 12;
  static const double _fontSize14 = 14;
  static const double _fontSize16 = 16;
  static const double _fontSize18 = 18;
  static const double _fontSize20 = 20;
  static const double _fontSize24 = 24;
  static const double _fontSize32 = 32;
  static const String _fontFamily = 'Roboto';

  static ColorScheme get _colorScheme => const ColorScheme.light().copyWith(
    primary: _green,
    onPrimary: Colors.white,
    primaryContainer: _green,
    secondary: _orange,
    onSecondary: Colors.white,
    surface: _surface,
    surfaceContainer: _surfaceMuted, // card / chip fill
    surfaceContainerHigh: _surfaceMutedHigh, // inputs / nav
    onSurface: _ink, // primary text
    onSurfaceVariant: _slateText, // secondary / muted text
    outline: _hairline, // borders & dividers
    error: _red,
    onError: Colors.white,
  );

  /// --- Global Typography System ---
  ///
  /// Every piece of text in the app picks one of these and, at most,
  /// `copyWith`s a colour or a weight onto it.
  static const TextTheme _textTheme = TextTheme(
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize16,
      color: _slateText,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize14,
      color: _slateText,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize12,
      color: _slateText,
      height: 1.4,
    ),
    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize20,
      fontWeight: FontWeight.w700,
      color: _ink,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize18,
      fontWeight: FontWeight.w600,
      color: _ink,
      height: 1.3,
    ),
    titleSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize16,
      fontWeight: FontWeight.w600,
      color: _ink,
      height: 1.3,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize14,
      fontWeight: FontWeight.w600,
      color: _ink,
    ),
    labelMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize12,
      fontWeight: FontWeight.w500,
      color: _slateText,
    ),
    headlineSmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize20,
      fontWeight: FontWeight.bold,
      color: _ink,
      height: 1.3,
    ),
    // The label on a full-width primary action, and the single letter in an
    // avatar: the biggest type that is not a screen title.
    headlineLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize24,
      fontWeight: FontWeight.bold,
      color: _ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: _fontSize32,
      fontWeight: FontWeight.bold,
      color: _ink,
    ),
  );

  /// Lovable-style cards: white with a 1px hairline border, no shadow.
  static CardThemeData get _cardTheme => CardThemeData(
    color: _surface,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: AppRadius.cardBorder,
      side: BorderSide(color: _hairline),
    ),
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
  );

  static InputDecorationTheme _inputTheme(ColorScheme colorScheme) =>
      InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        hintStyle: const TextStyle(color: _slateText, fontSize: _fontSize14),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide(color: _hairline),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.cardBorder,
          borderSide: BorderSide(color: _hairline),
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

  static ThemeData get light {
    final colorScheme = _colorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      extensions: const [
        CustomColors(
          success: _greenSuccess,
          lost: _blue,
          errorMuted: _red,
          accentMuted: _green,
        ),
      ],

      textTheme: _textTheme,

      // --- Component Themes ---
      cardTheme: _cardTheme,
      inputDecorationTheme: _inputTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),

      dividerTheme: const DividerThemeData(color: _hairline, thickness: 1),
    );
  }

  /// [light], with its foregrounds turned over for the dark gradient the start
  /// screen paints. A screen on that backdrop wraps itself in this.
  ///
  /// Every colour in the app comes from the theme, and the app's theme is a
  /// light one — so on the one dark surface the wordmark and the carousel
  /// titles were near-black type on a near-black gradient (#85). The backdrop
  /// is a different surface, so it gets the theme of that surface.
  static ThemeData get startBackdrop {
    final base = light;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        surface: startGradientTop,
        onSurface: _onDark,
        onSurfaceVariant: _onDarkMuted,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _onDarkMuted,
        displayColor: _onDark,
      ),
    );
  }
}
