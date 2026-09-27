import 'package:flutter/material.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';

/// A whole-screen message about a state that is not a failure: an empty list,
/// a wait, or something the student has to do first. An icon, a title, an
/// optional body and an optional button.
///
/// A failure is never one of these — it is a `FailureView` or a snackbar, both
/// in `core/widgets/failure.dart`.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => StateLayout(
    icon: icon,
    iconColor: Theme.of(context).colorScheme.primary,
    heading: title,
    text: body,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

/// The layout [StateMessage] and `FailureView` share: an icon, a heading, a
/// line of text and a button, centred in the empty space. Each of the two says
/// what it is about; this only lays it out, once, so the two cannot drift
/// apart (#231).
class StateLayout extends StatelessWidget {
  const StateLayout({
    super.key,
    required this.icon,
    required this.iconColor,
    this.heading,
    this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String? heading;
  final String? text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.stateIcon, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            if (heading != null)
              Text(
                heading!,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            if (heading != null && text != null)
              const SizedBox(height: AppSpacing.xs),
            if (text != null)
              Text(
                text!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
