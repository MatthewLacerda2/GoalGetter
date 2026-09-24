import 'package:flutter/material.dart';

/// Corner radii and spacing, the two halves of the design system that used to
/// be written by hand in every screen.
///
/// Colour and type already came from [ThemeData]; radius and spacing did not,
/// so the app grew thirteen different ways to round a corner and fifteen ways
/// to pad a box. These are the tokens, and `tool/frontend_linter.dart` refuses
/// a raw number outside `lib/app/theme/`.

/// The corner radii the design uses. Six, each with a job.
///
/// `<name>` is the raw value, for the rare call that needs a `double`;
/// `<name>Border` is the same value as a const [BorderRadius], so a decoration
/// that used to be const stays const.
abstract final class AppRadius {
  /// Fully rounded: page dots, pills, anything whose corner is its height.
  static const double pill = 999;

  /// Chat surfaces: message bubbles and the composer.
  static const double bubble = 24;

  /// Chips, stat tiles and the filled blocks a screen is built from.
  static const double chip = 20;

  /// Cards, inputs and buttons — the default corner, and what the
  /// component themes in [AppTheme] round to.
  static const double card = 16;

  /// Small controls living inside a card: thumbnails, badges, inner tiles.
  static const double control = 12;

  /// Progress bars and other hairline-thin shapes.
  static const double hairline = 4;

  static const BorderRadius pillBorder = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius bubbleBorder = BorderRadius.all(
    Radius.circular(bubble),
  );
  static const BorderRadius chipBorder = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(card));
  static const BorderRadius controlBorder = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius hairlineBorder = BorderRadius.all(
    Radius.circular(hairline),
  );
}

/// The spacing scale: 4-point steps, and nothing between them.
///
/// Every padding, margin and gap picks a step. A layout that seems to need
/// 7 or 18 is asking for a step that does not exist, and rounding it to the
/// nearest one has never yet been visible.
abstract final class AppSpacing {
  static const double none = 0;

  /// 4 — inside a badge, between an icon and its label.
  static const double xxs = 4;

  /// 8 — dense rows, chip interiors.
  static const double xs = 8;

  /// 12 — the gap between siblings in a list.
  static const double sm = 12;

  /// 16 — the default: card padding, screen gutters.
  static const double md = 16;

  /// 20 — a roomier card or button interior.
  static const double lg = 20;

  /// 24 — the gap between sections.
  static const double xl = 24;

  /// 32 — the space around a screen's hero block.
  static const double xxl = 32;
}

/// The few sizes that are neither a gap nor a corner: measures a layout has to
/// know about a component it does not draw itself.
abstract final class AppSizes {
  /// The band a floating snackbar occupies, its gap included.
  ///
  /// A floating snackbar is positioned by the margin left *under* it, so
  /// putting one at the top of the screen means reserving everything below it
  /// — and that calculation has to know how tall the snackbar is.
  static const double snackBarBand = 96;

  /// The icon of a whole-screen state: a failure, an empty list, a wait.
  static const double stateIcon = 48;

  /// A small icon sitting inside a line of text.
  static const double inlineIcon = 16;
}
