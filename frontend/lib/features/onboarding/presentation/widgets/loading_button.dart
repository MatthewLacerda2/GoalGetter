import 'package:flutter/material.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';

/// The filled button that sends an onboarding step: its label, or a spinner
/// in the label's place while the call is in flight. The goal prompt and the
/// study plan both send with it.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;

  /// Null disables the button; the caller decides whether a loading step may
  /// be pressed again.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: AppSizes.spinner,
              width: AppSizes.spinner,
              child: CircularProgressIndicator(
                strokeWidth: AppStroke.thick,
                valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
              ),
            )
          : Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: scheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
