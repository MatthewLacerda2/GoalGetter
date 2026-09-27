import 'package:flutter/material.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';

/// The card an onboarding question is asked on, above its options. The
/// questions Gemini writes and the standard ones are asked on the same card.
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Text(
        question,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
