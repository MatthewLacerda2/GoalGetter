import 'package:flutter/material.dart';

import 'package:goal_getter/app/theme/app_dimens.dart';

/// The pieces the lesson screen is made of, one widget each, so answering a
/// question rebuilds the tile that changed rather than the whole screen.

/// "3 / 10" and the bar that fills with it.
class LessonProgressRow extends StatelessWidget {
  const LessonProgressRow({
    super.key,
    required this.index,
    required this.total,
  });

  /// Zero-based index of the question on screen.
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '${index + 1} / $total',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(width: 16.0),
        Expanded(
          child: LinearProgressIndicator(
            value: (index + 1) / total,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The question itself, in its tinted box.
class LessonQuestionCard extends StatelessWidget {
  const LessonQuestionCard({super.key, required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        question,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

/// One answer. [fill] carries the state: selected, right, wrong or untouched.
class LessonChoiceTile extends StatelessWidget {
  const LessonChoiceTile({
    super.key,
    required this.label,
    required this.fill,
    required this.onTap,
  });

  final String label;
  final Color fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }
}

/// "Enter" before the answer is revealed, "Continue" after; [color] says
/// whether the revealed answer was right.
class LessonAnswerButton extends StatelessWidget {
  const LessonAnswerButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.headlineSmall?.copyWith(
            // Muted while disabled: white on the grey fill was unreadable.
            color: onPressed == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
