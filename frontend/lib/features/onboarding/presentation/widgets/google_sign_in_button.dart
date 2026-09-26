import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/features/onboarding/presentation/sign_in_routing.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

import 'google_rendered_button.dart'
    if (dart.library.js_interop) 'google_rendered_button_web.dart';

/// How far the button has got towards being able to sign anyone in.
enum _Ready {
  /// The GIS SDK is still loading. Nothing can be pressed yet.
  loading,

  /// It loaded: on the web Google's own button is drawn, on mobile ours is.
  ready,

  /// It did not load. The button is still pressable, so pressing it can say
  /// so rather than leaving the student with a spinner and no explanation.
  failed,
}

/// The one way into the app: signing in with Google.
///
/// **One screen, two mechanisms** (#84). On the web the GIS SDK allows no
/// programmatic sign-in, so the button is *Google's own*, rendered into the
/// page, and the result arrives on `AuthService.googleTokens`. On mobile the
/// app draws the button and a tap opens Google's sheet — whose result reaches
/// the very same stream. So everything after "Google said yes" is one path:
/// exchange the token for a session (POST /auth/signup), then route.
///
/// Where it routes is [routeAfterSignIn]: back to the goal draft the student
/// was committing when there is one, else wherever a launch would go.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  _Ready _ready = _Ready.loading;
  bool _isExchanging = false;
  StreamSubscription<String>? _tokens;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _tokens?.cancel();
    super.dispose();
  }

  /// Loads the SDK and subscribes to the sign-ins it will report.
  ///
  /// The subscription is made before the button can be pressed, because on the
  /// web the press happens inside Google's own button and the stream is the
  /// only thing that hears about it.
  Future<void> _prepare() async {
    final auth = ref.read(authServiceProvider);
    try {
      await auth.ensureInitialized();
    } on Object catch (error) {
      developer.log('Google Sign-In failed to initialize: $error');
      if (mounted) setState(() => _ready = _Ready.failed);
      return;
    }
    // Loading the SDK is a round trip, so the screen may already be gone;
    // subscribing now would outlive the dispose that would have cancelled it.
    if (!mounted) return;
    _tokens = auth.googleTokens().listen(_exchange, onError: _sayItFailed);
    setState(() => _ready = _Ready.ready);
  }

  /// Mobile only: opens Google's sheet. The token it produces comes back
  /// through the stream, so there is nothing to do with the result here.
  Future<void> _startSignIn() async {
    try {
      await ref.read(authServiceProvider).startGoogleSignIn();
    } on Object catch (error) {
      _sayItFailed(error);
    }
  }

  /// Turns Google's token into a session of ours, then leaves the screen.
  Future<void> _exchange(String googleToken) async {
    if (!mounted) return;
    setState(() => _isExchanging = true);
    try {
      await ref.read(authServiceProvider).signupWithGoogle(googleToken);
      if (mounted) await routeAfterSignIn(ref, context);
    } on Object catch (error) {
      _sayItFailed(error);
    } finally {
      if (mounted) setState(() => _isExchanging = false);
    }
  }

  /// Google refused, the exchange failed, or the SDK never loaded: the student
  /// pressed something and nothing happened, so say so where it happened.
  void _sayItFailed(Object error) {
    developer.log('Google sign-in failed: $error');
    if (!mounted) return;
    showFailure(
      context,
      error,
      title: AppLocalizations.of(context).signInFailed,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isExchanging || _ready == _Ready.loading) {
      return const _GoogleButton(isLoading: true, onPressed: null);
    }
    if (_ready == _Ready.ready && googleRendersItsOwnButton) {
      return const _RenderedByGoogle();
    }
    return _GoogleButton(isLoading: false, onPressed: _startSignIn);
  }
}

/// Google's own button, in the same box ours occupies so the layout does not
/// move when the SDK finishes loading and one replaces the other.
class _RenderedByGoogle extends StatelessWidget {
  const _RenderedByGoogle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.signInButton,
      child: LayoutBuilder(
        builder: (context, constraints) => googleRenderedButton(
          // Google will not draw one wider than this, and a button wider than
          // the box it is centred in would be clipped.
          width: math.min(constraints.maxWidth, AppSizes.googleButtonMaxWidth),
          locale: Localizations.localeOf(context).languageCode,
        ),
      ),
    );
  }
}

/// "Start with Google", in Google's own blue; a spinner while signing in.
///
/// What mobile presses, and what the web shows while the SDK loads — or
/// instead of Google's button when it never loaded, so a press can explain.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onBlue = Theme.of(context).colorScheme.onPrimary;
    return SizedBox(
      width: double.infinity,
      height: AppSizes.signInButton,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(onBlue),
                ),
              )
            : FaIcon(FontAwesomeIcons.google, color: onBlue, size: 20),
        label: Text(
          isLoading ? l10n.signingIn : l10n.startWithGoogle,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: onBlue,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.googleBlue,
          foregroundColor: onBlue,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
    );
  }
}
