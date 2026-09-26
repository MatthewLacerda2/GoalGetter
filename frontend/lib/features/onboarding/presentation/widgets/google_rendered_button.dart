/// Off the web, Google renders no button of its own: the app draws one and
/// calls `AuthService.startGoogleSignIn`.
///
/// This is the default half of the conditional import in
/// `google_sign_in_button.dart`; `google_rendered_button_web.dart` is the
/// other. Both declare the same two names, so the button widget itself never
/// asks which platform it is on — it asks [googleRendersItsOwnButton].
library;

import 'package:flutter/widgets.dart';

/// False: on Android and iOS the GIS SDK is not what draws the button.
const bool googleRendersItsOwnButton = false;

/// Never reached. [googleRendersItsOwnButton] is false here, and it is what
/// decides whether the button widget asks for Google's own button at all.
Widget googleRenderedButton({double? width, String? locale}) =>
    throw UnsupportedError(
      'Google renders its own sign-in button on the web only.',
    );
