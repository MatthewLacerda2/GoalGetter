import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/config/app_config.dart';
import 'package:goal_getter/core/widgets/language_picker.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/dev_login_button.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/google_sign_in_button.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/pre_onboarding_carousel.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/app/theme/app_theme.dart';

/// The app's front door, and the only place a student signs in.
///
/// Two things to press, because the screen is reached two ways round. Signing
/// in with Google ([GoogleSignInButton]) is what a returning student wants,
/// and what the study plan sends a visitor here for: creating the goal is the
/// first authed call, and the sign-in brings him back to the very draft he was
/// committing. Starting without an account is the other way: goal creation's
/// first two steps are public (backend_contract.md, Goals), so anyone can
/// describe what he wants to learn and see what the app makes of it before
/// deciding to sign in at all. Before #84 only the second existed, and the
/// button that said "Google" did it — so a real visitor could reach the point
/// of committing a goal and then had nothing to press.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The gradient is the app's one dark surface, so everything drawn on it
    // reads from the theme of that surface and not from the light one (#85).
    // Every child is its own widget, so each one sees this theme.
    return Theme(
      data: AppTheme.startBackdrop,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.startGradientTop, AppTheme.startGradientBottom],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // The language, already the phone's: one tap fixes it when
                  // the phone (or the browser) is wrong (#172).
                  const Align(
                    alignment: Alignment.topRight,
                    child: LanguageSelector(),
                  ),
                  const Spacer(flex: 2),
                  const _Wordmark(),
                  const SizedBox(height: AppSpacing.xl),
                  const PreOnboardingCarousel(height: _carouselHeight),
                  const Spacer(flex: 2),
                  // A DEV_LOGIN build offers the fictitious sign-in in place
                  // of Google; everything else gets the Google button.
                  if (AppConfig.devLogin)
                    const DevLoginButton()
                  else
                    const GoogleSignInButton(),
                  const _StartWithoutAccount(),
                  const _Terms(),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How tall the pitch carousel stands on the start screen.
const double _carouselHeight = 170;

/// The public half of goal creation: describe the goal, see what the app would
/// teach, and only then sign in to keep it.
class _StartWithoutAccount extends StatelessWidget {
  const _StartWithoutAccount();

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go(AppRoutes.goalPrompt),
      child: Text(AppLocalizations.of(context).tryWithoutSigningIn),
    );
  }
}

/// The line under the sign-in button.
class _Terms extends StatelessWidget {
  const _Terms();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).agreeToTermsAndPrivacyPolicy,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
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
        Text(
          AppLocalizations.of(context).appWordmark,
          style: theme.textTheme.headlineMedium,
        ),
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
