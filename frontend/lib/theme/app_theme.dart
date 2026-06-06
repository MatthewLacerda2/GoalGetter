import 'package:flutter/material.dart';

/// 1. CUSTOM SEMANTIC TOKENS (Tailwind-like custom design tokens)
/// Retrieve via `Theme.of(context).extension<CustomColors>()!.success`
class CustomColors extends ThemeExtension<CustomColors> {
  final Color? success;
  final Color? errorMuted;
  final Color? accentMuted;

  const CustomColors({this.success, this.errorMuted, this.accentMuted});

  @override
  CustomColors copyWith({Color? success, Color? errorMuted, Color? accentMuted}) {
    return CustomColors(
      success: success ?? this.success,
      errorMuted: errorMuted ?? this.errorMuted,
      accentMuted: accentMuted ?? this.accentMuted,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      success: Color.lerp(success, other.success, t),
      errorMuted: Color.lerp(errorMuted, other.errorMuted, t),
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t),
    );
  }
}

/// 2. THE MAIN THEME CONFIGURATION
class AppTheme {
  AppTheme._();

  // --- Primitive Tokens (Private to this file only) ---
  static const _charcoal = Color(0xFF121212);
  static const _darkGrey = Color(0xFF1E1E1E);
  static const _mediumGrey = Color(0xFF252525);
  static const _lithium = Color(0xFFE8E8E8);
  static const _coolGrey = Color(0xFFA0A0A0);
  static const _slate = Color(0xFF6B6B6B);
  
  static const _emerald = Color(0xFF2D9D78);
  static const _gold = Color(0xFFC49450);
  static const _mint = Color(0xFF5A8B7A);
  
  static const _green = Color(0xFF3DA872);
  static const _red = Color(0xFFC75C5C);
  static const _roseMuted = Color(0xFF8B5A5A);

  // --- Layout & Spacing Constants (Public for margins, paddings, and alignment) ---
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing24 = 24;
  static const double spacing32 = 32;

  static const double cardPadding = 24;
  static const double cardRadius = 20;
  static const double chatBubbleRadius = 24;
  static const double cardElevation = 2;
  static const double edgePadding = spacing16;
  static const double sectionGap = spacing32;
  static const double elementGap = spacing16;

  static const double fontSize12 = 12;
  static const double fontSize14 = 14;
  static const double fontSize16 = 16;
  static const double fontSize18 = 18;
  static const double fontSize20 = 20;

  static const double notesHeadingSize = 20;
  static const String _fontFamily = 'Roboto';

  static ThemeData get dark {
    // --- Semantic Color Tokens (Material 3 ColorScheme) ---
    final colorScheme = const ColorScheme.dark().copyWith(
      primary: _emerald,
      onPrimary: Colors.white,
      primaryContainer: _mint, 
      secondary: _gold,
      onSecondary: Colors.white,
      surface: _charcoal,
      surfaceContainer: _darkGrey,       // Modern M3 card background replacement
      surfaceContainerHigh: _mediumGrey,  // Modern M3 inputs / navigation background replacement
      onSurface: _lithium,               // Main primary text
      onSurfaceVariant: _coolGrey,       // Secondary / muted text
      outline: _slate,                   // Borders & dividers
      error: _red,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // Inject Tailwind-like custom tokens
      extensions: const [
        CustomColors(
          success: _green,
          errorMuted: _roseMuted,
          accentMuted: _mint,
        ),
      ],

      // --- Global Typography System ---
      textTheme: TextTheme(
        bodyLarge: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: fontSize16,
          fontWeight: FontWeight.normal,
          color: _coolGrey,
          height: 1.5,
        ),
        bodyMedium: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: fontSize14,
          fontWeight: FontWeight.normal,
          color: _coolGrey,
          height: 1.5,
        ),
        bodySmall: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: fontSize12,
          fontWeight: FontWeight.normal,
          color: _coolGrey,
          height: 1.4,
        ),
        titleLarge: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: fontSize20,
          fontWeight: FontWeight.w600,
          color: _lithium,
          height: 1.3,
        ),
        titleMedium: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: fontSize18,
          fontWeight: FontWeight.w600,
          color: _lithium,
          height: 1.3,
        ),
        titleSmall: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: fontSize16,
          fontWeight: FontWeight.w500,
          color: _lithium,
          height: 1.3,
        ),
        labelLarge: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: fontSize14,
          fontWeight: FontWeight.w500,
          color: _lithium,
        ),
        labelMedium: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: fontSize12,
          fontWeight: FontWeight.w500,
          color: _coolGrey,
        ),
        headlineSmall: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: notesHeadingSize,
          fontWeight: FontWeight.bold,
          color: _lithium,
          height: 1.3,
        ),
        headlineMedium: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: _lithium,
          letterSpacing: 1.2,
        ),
      ),

      // --- Component Themes (Driven by semantic colorScheme) ---
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainer,
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        hintStyle: const TextStyle(color: _coolGrey, fontSize: fontSize14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide(
            color: _slate.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
