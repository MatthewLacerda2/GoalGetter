import 'package:flutter/material.dart';

import 'package:goal_getter/core/theme/app_dimens.dart';
import 'package:goal_getter/core/theme/app_theme.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/lesson_state.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The pieces the lesson screen is made of, one widget each, so answering a
/// question rebuilds the tile that changed rather than the whole screen.

/// A question of the lesson as the student answers it: the progress, the
/// question, its choices and the one button. It draws [state] and hands every
/// tap to the controller through the callbacks.
class LessonQuestionPage extends StatelessWidget {
  const LessonQuestionPage({
    required this.state,
    required this.onSelect,
    required this.onEnter,
    required this.onContinue,
    super.key,
  });

  final LessonAnswering state;
  final ValueChanged<int> onSelect;
  final VoidCallback onEnter;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final question = state.current.question;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          LessonProgressRow(index: state.index, total: state.questions.length),
          const SizedBox(height: AppSpacing.xxl),
          LessonQuestionCard(question: question.question),
          const SizedBox(height: AppSpacing.gap40),
          Expanded(
            child: ListView.builder(
              itemCount: question.choices.length,
              itemBuilder: (context, index) => LessonChoiceTile(
                label: question.choices[index],
                fill: _choiceFill(context, index),
                onTap: () => onSelect(index),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LessonAnswerButton(
            label: state.isRevealed ? l10n.continuate : l10n.enter,
            color: _buttonColor(context),
            onPressed: state.selectedChoice == null
                ? null
                : (state.isRevealed ? onContinue : onEnter),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ),
    );
  }

  Color _success(BuildContext context) =>
      CustomColors.of(context).success;

  /// Tapped, before the answer is entered; after it, right, wrong or neither.
  Color _choiceFill(BuildContext context, int index) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = state.selectedChoice == index;
    if (!state.isRevealed) {
      return isSelected
          ? scheme.primary.withValues(alpha: AppOpacity.tint)
          : scheme.surfaceContainerHigh;
    }
    if (index == state.current.question.correctAnswerIndex) {
      return _success(context).withValues(alpha: AppOpacity.tint);
    }
    if (isSelected) return scheme.error.withValues(alpha: AppOpacity.tint);
    return scheme.outline.withValues(alpha: AppOpacity.faint);
  }

  /// Grey until a choice is tapped; once entered, whether it was right.
  Color _buttonColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (state.selectedChoice == null) return scheme.outline;
    if (!state.isRevealed) return scheme.primary;
    return state.current.isCorrect ? _success(context) : scheme.error;
  }
}

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
        SizedBox(width: AppSpacing.md),
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
