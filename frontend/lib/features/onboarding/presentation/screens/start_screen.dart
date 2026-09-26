import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/core/config/app_config.dart';
import 'package:goal_getter/core/widgets/language_picker.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/dev_login_button.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/google_sign_in_button.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The app's front door, and the only place a student signs in.
///
/// **What it says** (#180): the page a visitor decides on, so it says what the
/// app is in one glance — the icon and the name, a headline, and four short
/// lines a visitor reads without scrolling or waiting for a carousel. It never
/// speaks of courses or of reaching a goal: a goal is what the student wants to
/// learn about, and there is no finish line (`CLAUDE.md`, "How the app
/// decides"). The headline and the tagline under it are the two phrasings the
/// user weighed; swapping the values of `startHeadline` and `startTagline` in
/// the ARB files swaps which one leads.
///
/// **How it looks**: the app's own theme, light or dark like every other
/// screen. Until #180 it painted a dark gradient in both modes (#85), which
/// made the one page a visitor judges the app by the one page that did not
/// look like it.
///
/// **What it does** — two ways in, because the screen is reached two ways
/// round. Signing in with Google ([GoogleSignInButton]) is what a returning
/// student wants, and what the study plan sends a visitor here for: creating
/// the goal is the first authed call, and the sign-in brings him back to the
/// very draft he was committing. Trying it without an account is the other:
/// goal creation's first two steps are public (backend_contract.md, Goals), so
/// anyone can describe what he wants to learn and see what the app makes of it
/// before deciding to sign in at all (#84).
class StartScreen extends StatelessWidget {
  const StartScreen({super.key, this.devLogin = AppConfig.devLogin});

  /// Whether this build offers the fictitious sign-in in place of Google's.
  /// [AppConfig.devLogin] everywhere but in a test, which cannot rebuild the
  /// app with another `--dart-define`.
  final bool devLogin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // Scrolls only when it must — a short phone, large text — and
        // otherwise fills the screen, the pitch centred between the language
        // and the ways in. No IntrinsicHeight: on the web Google's button
        // sits in a LayoutBuilder, which cannot report one.
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - AppSpacing.md * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // The language, already the phone's: one tap fixes it when
                  // the phone (or the browser) is wrong (#172).
                  const Align(
                    alignment: Alignment.topRight,
                    child: LanguageSelector(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: _Pitch(),
                  ),
                  _WaysIn(devLogin: devLogin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The icon and the name, the headline, and what the app does in four lines.
class _Pitch extends StatelessWidget {
  const _Pitch();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: AppRadius.chipBorder,
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: AppSizes.startIcon,
            height: AppSizes.startIcon,
            // The name is written right under it.
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.appWordmark,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          l10n.startHeadline,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.startTagline,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // One block, left-aligned inside and centred as a whole, so the icons
        // line up whatever the length of each sentence.
        IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Point(Icons.lightbulb_outline, l10n.startPointSubject),
              _Point(Icons.timer_outlined, l10n.startPointDaily),
              _Point(Icons.trending_up, l10n.startPointLevel),
              _Point(Icons.chat_bubble_outline, l10n.startPointTutor),
            ],
          ),
        ),
      ],
    );
  }
}

/// One line of the pitch: an icon in the accent, then the sentence.
class _Point extends StatelessWidget {
  const _Point(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Signing in, trying it without an account, and the terms under both.
class _WaysIn extends StatelessWidget {
  const _WaysIn({required this.devLogin});

  final bool devLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        // A DEV_LOGIN build offers the fictitious sign-in in place of
        // Google; everything else gets the Google button.
        if (devLogin) const DevLoginButton() else const GoogleSignInButton(),
        const SizedBox(height: AppSpacing.xs),
        // The public half of goal creation: describe the goal, see what the
        // app would teach, and only then sign in to keep it.
        TextButton(
          onPressed: () => context.go(AppRoutes.goalPrompt),
          child: Text(l10n.tryWithoutSigningIn),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.agreeToTermsAndPrivacyPolicy,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
