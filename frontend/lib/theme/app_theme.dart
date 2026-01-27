import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF121212);

  static const Color cardBackground = Color(0xFF1E1E1E);

  static const Color surfaceVariant = Color(0xFF252525);

  static const Color textPrimary = Color(0xFFE8E8E8);

  static const Color textSecondary = Color(0xFFA0A0A0);

  static const Color textTertiary = Color(0xFF6B6B6B);

  static const Color accentPrimary = Color(0xFF2D9D78);

  static const Color accentSecondary = Color(0xFFC49450);

  static const Color accentMuted = Color(0xFF5A8B7A);

  static const Color success = Color(0xFF3DA872);
  static const Color error = Color(0xFFC75C5C);
  static const Color errorMuted = Color(0xFF8B5A5A);

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

  static TextTheme get textTheme {
    return TextTheme(
      bodyLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize16,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.5,
      ),
      bodyMedium: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize14,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
        height: 1.4,
      ),
      titleLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.3,
      ),
      titleMedium: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.3,
      ),
      titleSmall: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.3,
      ),
      labelLarge: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelMedium: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: fontSize12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      headlineSmall: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: notesHeadingSize,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        height: 1.3,
      ),
      headlineMedium: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: 1.2,
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: accentPrimary,
      onPrimary: Colors.white,
      secondary: accentSecondary,
      onSecondary: Colors.white,
      surface: background,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      error: error,
      onError: Colors.white,
      outline: textTertiary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        hintStyle: const TextStyle(color: textSecondary, fontSize: fontSize14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide(
            color: textTertiary.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: const BorderSide(color: accentPrimary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: Colors.white,
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

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceVariant,
        selectedItemColor: accentPrimary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
