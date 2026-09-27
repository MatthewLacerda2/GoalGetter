import 'package:flutter/material.dart';

/// Every colour one theme mode paints with. `AppTheme` builds light and dark
/// from the same code over one of these two, so switching modes changes the
/// palette and nothing else: the fonts, the type scale, the shapes and the
/// spacing are shared (#178).
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceMutedHigh,
    required this.ink,
    required this.body,
    required this.muted,
    required this.hairline,
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.success,
    required this.lost,
    required this.error,
    required this.errorMuted,
    required this.accentMuted,
  });

  final Brightness brightness;

  /// The page, and anything that sits flat on it.
  final Color surface;

  /// Chip and filled-field background.
  final Color surfaceMuted;

  /// Inputs, the tutor's chat bubble.
  final Color surfaceMutedHigh;

  /// Titles and primary text.
  final Color ink;

  /// Running text (`bodySmall` to `bodyLarge`).
  final Color body;

  /// Secondary text, labels, hints.
  final Color muted;

  /// Borders and dividers.
  final Color hairline;

  final Color primary;
  final Color primaryContainer;

  /// The streak flame and the elo stat.
  final Color secondary;

  /// Elo gained, a right answer. Painted as a fill under white text, so it
  /// must stay dark enough for that in both modes.
  final Color success;

  /// Elo lost.
  final Color lost;
  final Color error;
  final Color errorMuted;
  final Color accentMuted;

  /// What sits on [primary], [error] and [success] fills: white in both modes.
  static const onFill = Colors.white;

  static const light = AppPalette(
    brightness: Brightness.light,
    surface: Colors.white,
    surfaceMuted: Color(0xFFF5F5F7),
    surfaceMutedHigh: Color(0xFFEDEDF0),
    ink: Color(0xFF1A1A1A),
    body: Color(0xFF6B7280),
    muted: Color(0xFF6B7280),
    hairline: Color(0xFFE5E7EB),
    primary: Color(0xFF2D9D78),
    primaryContainer: Color(0xFF2D9D78),
    secondary: Color(0xFFF1820A),
    success: Color(0xFF16A34A),
    lost: Color(0xFF2563EB),
    error: Color(0xFFDC2626),
    errorMuted: Color(0xFFDC2626),
    accentMuted: Color(0xFF2D9D78),
  );

  /// The user's own dark palette, from commit 3d8ac4d (2026-06-06) on
  /// `backup/local-theme-2026-09-23`: its colours, none of its identity.
  /// Two departures, both for readability: [success] keeps the light green,
  /// since that commit's `#4ADE80` carries white text at 1.9:1 on the lesson's
  /// check button; and [lost], which that commit never had, keeps the light
  /// blue.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    surface: Color(0xFF0F1412), // charcoal
    surfaceMuted: Color(0xFF161E1A),
    surfaceMutedHigh: Color(0xFF252525),
    ink: Color(0xFFE8E8E8), // lithium
    body: Color(0xFFE8E8E8), // that commit's "reading contrast" change
    muted: Color(0xFFA0A0A0), // cool grey
    hairline: Color(0xFF6B6B6B), // slate
    primary: Color(0xFF2D9D78), // emerald
    primaryContainer: Color(0xFF5A8B7A), // mint
    secondary: Color(0xFFC49450), // gold
    success: Color(0xFF16A34A),
    lost: Color(0xFF2563EB),
    error: Color(0xFFC75C5C),
    errorMuted: Color(0xFF8B5A5A), // rose muted
    accentMuted: Color(0xFF5A8B7A), // mint
  );
}
