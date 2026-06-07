import 'package:flutter/material.dart';

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

  // --- Private Primitive Spacing & Dimensions ---
  static const double _spacing12 = 12;
  static const double _spacing16 = 16;
  static const double _spacing24 = 24;

  static const double _cardRadius = 16;

  static const double _fontSize12 = 12;
  static const double _fontSize14 = 14;
  static const double _fontSize16 = 16;
  static const double _fontSize18 = 18;
  static const double _fontSize20 = 20;
  static const String _fontFamily = 'Roboto';

  static ThemeData get light {
    final colorScheme = const ColorScheme.light().copyWith(
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

      // --- Global Typography System ---
      textTheme: const TextTheme(
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
        headlineMedium: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _ink,
        ),
      ),

      // --- Component Themes ---
      // Lovable-style cards: white with a 1px hairline border, no shadow.
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          side: const BorderSide(color: _hairline),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        hintStyle: const TextStyle(color: _slateText, fontSize: _fontSize14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          borderSide: const BorderSide(color: _hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          borderSide: const BorderSide(color: _hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: _spacing16,
          vertical: _spacing12,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(
            horizontal: _spacing24,
            vertical: _spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
          ),
        ),
      ),

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
}
