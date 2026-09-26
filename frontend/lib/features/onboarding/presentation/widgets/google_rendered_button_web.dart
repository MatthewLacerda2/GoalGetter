/// On the web, the sign-in button is Google's, not ours.
///
/// The GIS SDK refuses every programmatic sign-in — `google_sign_in_web`'s
/// `authenticate()` throws — and offers exactly one way in: render *their*
/// button and listen for the event it fires (`AuthService.googleTokens`).
/// That is why this file exists at all, and why the styled button the app
/// draws on mobile cannot be what the web uses (#84).
///
/// The widget it returns is a real DOM element over the Flutter canvas, so its
/// wording, its logo and its own localisation come from Google. Nothing here
/// is a sentence of ours, which is why no ARB key appears in this file.
library;

import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi;

/// True: this is the build where the SDK draws the button.
const bool googleRendersItsOwnButton = true;

/// Google's own sign-in button, at least [width] wide and in [locale].
///
/// A sign-in through it reaches the app as an event on
/// `AuthService.googleTokens`; the button itself reports nothing to Dart.
Widget googleRenderedButton({double? width, String? locale}) =>
    gsi.renderButton(
      configuration: gsi.GSIButtonConfiguration(
        type: gsi.GSIButtonType.standard,
        theme: gsi.GSIButtonTheme.filledBlue,
        size: gsi.GSIButtonSize.large,
        text: gsi.GSIButtonText.continueWith,
        shape: gsi.GSIButtonShape.pill,
        minimumWidth: width,
        locale: locale,
      ),
    );
