import 'package:flutter/material.dart';

import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/error_text.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The sentence for a failed goal-creation call: [errorText] (the backend's
/// `detail`; for a 400 from objective-questions, Gemini's reasoning), except
/// for the rate limit, whose slowapi body has no `detail` to show.
String onboardingErrorText(Object error, AppLocalizations l10n) {
  if (error is ApiException && error.status == 429) {
    return l10n.onboardingTooManyTries;
  }
  return errorText(error, l10n);
}

/// An inline error for a goal-creation step, with a retry when one helps.
class StepError extends StatelessWidget {
  const StepError({required this.error, super.key, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  onboardingErrorText(error, l10n),
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
          if (onRetry != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.onboardingRetry),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
