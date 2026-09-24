import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goal_actions.dart';
import 'package:goal_getter/features/goals/presentation/widgets/goal_card.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

enum _Busy { none, activating, deleting }

/// One goal, with the actions on it. It shows the goal it is given (an item of
/// `GET /goals`) and never fetches one: there is no per-goal GET.
class GoalsDetailScreen extends ConsumerStatefulWidget {
  const GoalsDetailScreen({super.key, required this.goal});

  final Goal goal;

  @override
  ConsumerState<GoalsDetailScreen> createState() => _GoalsDetailScreenState();
}

class _GoalsDetailScreenState extends ConsumerState<GoalsDetailScreen> {
  _Busy _busy = _Busy.none;

  /// The two buttons sit at the bottom of the screen, so the snackbar that
  /// says one of them failed goes to the top, where it covers neither.
  Future<void> _run(
    _Busy busy,
    Future<String> Function(GoalActions actions) action,
    String title,
    VoidCallback onRetry,
  ) async {
    final actions = ref.read(goalActionsProvider);
    setState(() => _busy = busy);
    try {
      final location = await action(actions);
      if (mounted) context.go(location);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _busy = _Busy.none);
      showFailure(
        context,
        e,
        title: title,
        onRetry: onRetry,
        position: FailurePosition.top,
      );
    }
  }

  Future<void> _setActive() => _run(
        _Busy.activating,
        (actions) => actions.setActive(widget.goal),
        AppLocalizations.of(context).setActiveGoalFailed,
        _setActive,
      );

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteGoal),
        content: Text(l10n.areYouSureYouWantToDeleteThisGoal),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _run(
      _Busy.deleting,
      (actions) => actions.delete(widget.goal),
      l10n.deleteGoalFailed,
      _delete,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watched so the actions' provider outlives an in-flight call.
    ref.watch(goalActionsProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final goal = widget.goal;
    final title = goal.name.isNotEmpty ? goal.name : l10n.untitledGoal;
    final idle = _busy == _Busy.none;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: scheme.surfaceContainerHigh,
        foregroundColor: scheme.onSurface,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _GoalSummary(goal: goal, title: title)),
            _GoalActions(
              busy: _busy,
              onSetActive: idle && !goal.isActive ? _setActive : null,
              onDelete: idle ? _delete : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything the detail screen says about the goal: title, elo, dates, body.
class _GoalSummary extends StatelessWidget {
  const _GoalSummary({required this.goal, required this.title});

  final Goal goal;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: theme.textTheme.headlineSmall),
            ),
            if (goal.isActive) const ActiveGoalBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${l10n.elo} ${goal.currentElo}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        GoalDates(goal: goal),
        const SizedBox(height: 16),
        if (goal.description.isNotEmpty)
          MarkdownBody(data: goal.description)
        else
          Text(l10n.noDescription),
      ],
    );
  }
}

/// The two buttons pinned under the goal.
class _GoalActions extends StatelessWidget {
  const _GoalActions({
    required this.busy,
    required this.onSetActive,
    required this.onDelete,
  });

  final _Busy busy;
  final VoidCallback? onSetActive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.none,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionButton(
            label: l10n.setAsCurrentGoal,
            color: scheme.primary,
            busy: busy == _Busy.activating,
            onPressed: onSetActive,
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: l10n.deleteGoal,
            color: scheme.error.withValues(alpha: 0.8),
            busy: busy == _Busy.deleting,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.chip)),
        elevation: 0,
      ),
      child: busy
          ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
    );
  }
}
