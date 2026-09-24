import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/config/app_config.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/dev_login_button.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/pre_onboarding_carousel.dart';
import 'package:goal_getter/features/onboarding/presentation/sign_in_routing.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/app/theme/app_theme.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  late final AuthService _authService = ref.read(authServiceProvider);
  bool _isLoading = false;
  bool _isGoogleInit = false;

  @override
  void initState() {
    super.initState();
    // A DEV_LOGIN build signs in without Google, so it never loads it.
    if (!AppConfig.devLogin) _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      developer.log('Initializing Google Sign-In...');
      await _authService.ensureInitialized();
      if (mounted) {
        setState(() {
          _isGoogleInit = true;
        });
      }

      // Listen to authentication changes
      if (kIsWeb) {
        GoogleSignIn.instance.authenticationEvents.listen((GoogleSignInAuthenticationEvent event) async {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            final GoogleSignInAccount account = event.user;
            developer.log('Google user stream event received: ${account.email}');
            await _handleGoogleSignInWeb(account);
          }
        });
      }
    } catch (e) {
      developer.log('Failed to initialize Google Sign-In: $e');
    }
  }

  Future<void> _handleGoogleSignInWeb(GoogleSignInAccount account) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final googleToken = await _authService.googleTokenFor(account);
      await _authService.signupWithGoogle(googleToken);
      if (mounted) await _routeAfterSignIn();
    } catch (error) {
      developer.log('Error handling Google web sign-in event: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).signInFailed(error.toString()),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _routeAfterSignIn() => routeAfterSignIn(ref, context);

  /// Goal creation's first two steps are public (backend_contract.md, Goals):
  /// the button starts them, and the Google sign-in (the listener above) is
  /// needed only to commit the goal.
  void _handleGoogleSignIn() => context.go(AppRoutes.goalPrompt);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.startGradientTop,
              AppTheme.startGradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(flex: 2),

                const _Wordmark(),

                SizedBox(height: 28),

                PreOnboardingCarousel(height: 170),

                Spacer(flex: 2),

                // A DEV_LOGIN build offers the fictitious sign-in in place of
                // Google; everything else gets the Google button.
                if (AppConfig.devLogin)
                  const DevLoginButton()
                else
                  _GoogleButton(
                    isLoading: _isLoading,
                    onPressed: _handleGoogleSignIn,
                  ),

                // Terms and Privacy
                Text(
                  AppLocalizations.of(context).agreeToTermsAndPrivacyPolicy,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's name over its one-line pitch.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Goal Getter', style: theme.textTheme.headlineMedium),
        Text(
          AppLocalizations.of(context).yourMentor,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w300,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// "Start with Google", in Google's own blue; a spinner while signing in.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onBlue = Theme.of(context).colorScheme.onPrimary;
    return SizedBox(
      width: double.infinity,
      height: 56,
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
          style: Theme.of(context).textTheme.labelLarge,
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
