import 'package:flutter/material.dart';

/// Corner radii and spacing, the two halves of the design system that used to
/// be written by hand in every screen.
///
/// Colour and type already came from [ThemeData]; radius and spacing did not,
/// so the app grew thirteen different ways to round a corner and fifteen ways
/// to pad a box. These are the tokens, and `tool/frontend_linter.dart` refuses
/// a raw number outside `lib/core/theme/`.

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

  // --- Off the scale ---
  //
  // The gaps screens wrote as `SizedBox(height: 10)` before the rule reached
  // them (#227). Each keeps the value it had, so bringing gaps under the rule
  // moved no pixel; named after the value, because that is all they are.
  // Moving one onto the scale above is a visual change, to be made where a
  // golden test (#226) shows it — and then the token goes.

  static const double gap3 = 3;
  static const double gap6 = 6;
  static const double gap10 = 10;
  static const double gap14 = 14;
  static const double gap28 = 28;
  static const double gap40 = 40;
  static const double gap48 = 48;
  static const double gap60 = 60;
}

/// How big an icon is drawn. [AppSizes.inlineIcon] and [AppSizes.stateIcon]
/// are the two with a job of their own; these are the rest.
abstract final class AppIconSize {
  /// Inside a dense row of text: a lesson's time and accuracy.
  static const double xs = 14;

  /// A chip's icon, a list trailing chevron, a small icon button.
  static const double sm = 18;

  /// A tile's leading icon, a brand mark on a button.
  static const double md = 20;

  /// A tab's icon.
  static const double tab = 22;

  /// A stat's icon, a thumbnail's placeholder.
  static const double lg = 24;

  /// The icon on the big "start lesson" action.
  static const double action = 26;

  /// The bottom navigation bar.
  static const double nav = 28;

  /// The single icon a celebration or an info screen is built around.
  static const double hero = 140;
}

/// Line widths: borders, strokes and dividers.
abstract final class AppStroke {
  /// A divider, an unselected card's border.
  static const double hairline = 1;

  /// A focused input's border.
  static const double focus = 1.5;

  /// A selected card's border, a progress spinner's stroke.
  static const double thick = 2;
}

/// Alphas a colour is tinted with, from the faintest wash to nearly opaque.
/// A tint is a colour decision, so its alpha is a token like the colour.
abstract final class AppOpacity {
  /// A selected option's wash.
  static const double wash = 0.08;

  /// A stat or a chip's fill, a quiet border.
  static const double faint = 0.12;

  /// The streak chip's fill.
  static const double soft = 0.14;

  /// An answer's fill once it is marked, a selectable option's border.
  static const double tint = 0.2;

  /// The composer's resting border.
  static const double medium = 0.4;

  /// A message still on its way.
  static const double pending = 0.6;

  /// Text in a colour that has to stay readable over a surface.
  static const double strong = 0.8;
}

/// Adjustments to the text theme a few screens make: line heights and the
/// letter spacing of an all-caps label.
abstract final class AppType {
  /// A tight headline.
  static const double headingHeight = 1.2;

  /// Running text the student types into.
  static const double bodyHeight = 1.5;

  /// Long text the student reads: a study plan, a tutor's reply.
  static const double readingHeight = 1.6;

  /// The letter spacing of a stat's caption.
  static const double captionSpacing = 0.6;

  /// The letter spacing of an all-caps section label.
  static const double labelSpacing = 1.2;

  /// The letter spacing of the profile's all-caps title.
  static const double titleSpacing = 1.5;
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

  /// What a scrolling list leaves under its last item so a floating action
  /// button (56 high, 16 off the edge) never covers it.
  static const double fabClearance = 88;

  /// The icon of a whole-screen state: a failure, an empty list, a wait.
  static const double stateIcon = 48;

  /// A small icon sitting inside a line of text.
  static const double inlineIcon = 16;

  /// The height of a sign-in button on the start screen.
  ///
  /// It is a token because two different buttons have to agree on it: the one
  /// the app draws, and the box Google's own rendered button is centred in on
  /// the web (#84). Without one number the layout jumps when the GIS SDK
  /// finishes loading and the second replaces the first.
  static const double signInButton = 56;

  /// The widest Google will draw its own sign-in button - the GIS SDK's own
  /// limit. Asking for more gets a button clipped by the box holding it.
  static const double googleButtonMaxWidth = 400;

  /// The app's icon at the top of the start screen, the one place it is
  /// drawn inside the app rather than by the platform (#180).
  static const double startIcon = 88;

  /// A progress spinner standing in for a button's label or icon.
  static const double spinner = 20;

  /// A progress spinner inside a row of text.
  static const double spinnerSmall = 18;

  /// The progress bar under a questionnaire's app bar.
  static const double progressBar = 6;

  /// The dev menu's banner under its app bar.
  static const double devBanner = 28;

  /// A language's flag.
  static const double flagWidth = 32;
  static const double flagHeight = 24;

  /// The rounded square a profile row's icon sits in.
  static const double tileIcon = 40;

  /// A resource's thumbnail.
  static const double thumbnail = 56;

  /// Google's sign-in button, which wears its brand's shadow.
  static const double googleButtonElevation = 2;
}
