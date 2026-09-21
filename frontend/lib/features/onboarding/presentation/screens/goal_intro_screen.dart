import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/intro_icons.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/pre_onboarding_carousel.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// Right after `POST /goals`: the goal's introduction screens, while the
/// backend prepares its resources and lessons, then home.
class GoalIntroScreen extends StatelessWidget {
  const GoalIntroScreen({super.key, required this.screens});

  final List<IntroScreenData> screens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      for (final s in screens)
        (icon: introIconFor(s.icon), title: s.title, body: s.text),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              if (items.isNotEmpty)
                PreOnboardingCarousel(height: 260, items: items),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(l10n.onboardingIntroContinue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
