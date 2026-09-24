import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// Primary call-to-action on the Home screen: starts the daily lesson.
///
/// Navigates to the lesson route; the lesson controller fetches a fresh activity
/// for the active goal.
class StartLessonButton extends StatelessWidget {
  const StartLessonButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppRoutes.lesson),
        icon: Icon(
          Icons.play_arrow,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 26,
        ),
        label: Text(
          AppLocalizations.of(context)!.startLesson,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
      ),
    );
  }
}
