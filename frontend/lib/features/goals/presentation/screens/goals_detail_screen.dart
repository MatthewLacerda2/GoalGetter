import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/core/utils/error_text.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goal_actions.dart';
import 'package:goal_getter/features/goals/presentation/widgets/goal_card.dart';

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
  String? _error;

  Future<void> _run(
    _Busy busy,
    Future<String> Function(GoalActions actions) action,
    String Function(String detail) describeFailure,
  ) async {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(goalActionsProvider);
    setState(() {
      _busy = busy;
      _error = null;
    });
    try {
      final location = await action(actions);
      if (mounted) context.go(location);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = _Busy.none;
        _error = describeFailure(errorText(e, l10n));
      });
    }
  }

  Future<void> _setActive() => _run(
        _Busy.activating,
        (actions) => actions.setActive(widget.goal),
        AppLocalizations.of(context).setActiveGoalFailed,
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
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
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: scheme.secondary),
                  ),
                  const SizedBox(height: 4),
                  GoalDates(goal: goal),
                  const SizedBox(height: 16),
                  if (goal.description.isNotEmpty)
                    MarkdownBody(data: goal.description)
                  else
                    Text(l10n.noDescription),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      key: const Key('goalActionError'),
                      style: TextStyle(color: scheme.error),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _ActionButton(
                    label: l10n.setAsCurrentGoal,
                    color: scheme.primary,
                    busy: _busy == _Busy.activating,
                    onPressed: idle && !goal.isActive ? _setActive : null,
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    label: l10n.deleteGoal,
                    color: scheme.error.withValues(alpha: 0.8),
                    busy: _busy == _Busy.deleting,
                    onPressed: idle ? _delete : null,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }
}
