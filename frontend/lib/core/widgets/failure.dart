/// One vocabulary for telling the student something failed, in two shapes.
///
///  * An **action** that failed — sending a message, liking a reply, setting
///    the active goal, deleting, submitting answers — is [showFailure]: a
///    snackbar over the screen the student is still on, so what they typed or
///    chose is untouched. It sits at the bottom, or at the top when something
///    at the bottom is what failed.
///  * A **screen** that could not load — home, the goals, the resources, the
///    tutor's history, the start of a lesson — is a [FailureView]: the reason
///    and a retry button, in the empty space. A snackbar would fade and leave
///    the student on a blank screen with nothing to press.
///
/// Both take whatever the API layer threw, read it with the same [errorText],
/// and offer the same retry. Nothing outside `lib/core/` may grow a third
/// shape: `tool/frontend_linter.dart` refuses a widget named after a failure.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/core/utils/error_text.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// Where a failure snackbar sits. The user finds merit in both.
enum FailurePosition { top, bottom }

/// A screen that could not load: what failed, why, and a button to try again.
class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.error, this.title, this.onRetry});

  /// What the call threw; null when there was nothing to throw.
  final Object? error;

  /// The line saying *what* could not be loaded. Without one the reason
  /// stands alone, which is enough when the screen has only one thing to load.
  final String? title;

  /// Null when trying again cannot help — then the view only explains.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: AppSizes.stateIcon, color: scheme.error),
            const SizedBox(height: AppSpacing.md),
            if (title != null) ...[
              Text(
                title!,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              errorText(error, l10n),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ],
        ),
      ),
    );
  }
}

/// An action that failed: a snackbar with the reason and, when the action can
/// simply be repeated, a retry. The screen keeps everything it had.
void showFailure(
  BuildContext context,
  Object? error, {
  String? title,
  VoidCallback? onRetry,
  FailurePosition position = FailurePosition.bottom,
}) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final onColor = theme.colorScheme.onErrorContainer;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: _margin(context, position),
        backgroundColor: theme.colorScheme.errorContainer,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(color: onColor),
              ),
            Text(
              errorText(error, l10n),
              style: theme.textTheme.bodyMedium?.copyWith(color: onColor),
            ),
          ],
        ),
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: l10n.retry,
                textColor: onColor,
                onPressed: onRetry,
              ),
      ),
    );
}

/// A floating snackbar is placed by the margin left *under* it, so the top
/// position is the whole screen minus the band the snackbar itself takes.
EdgeInsets _margin(BuildContext context, FailurePosition position) {
  if (position == FailurePosition.bottom) {
    return const EdgeInsets.all(AppSpacing.md);
  }
  final media = MediaQuery.of(context);
  final below = math.max(
    AppSpacing.none,
    media.size.height - media.padding.top - AppSizes.snackBarBand,
  );
  return EdgeInsets.only(
    left: AppSpacing.md,
    right: AppSpacing.md,
    bottom: below,
  );
}
