import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// A goal's date the way the goals screens print it, in the device's zone.
String formatGoalDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  return DateFormat.yMMMd(locale).format(date.toLocal());
}

/// The description without its markdown marks, for a one-glance preview.
String plainPreview(String markdown) => markdown
    .replaceAll(RegExp(r'^\s*([-+]|\d+\.)\s+', multiLine: true), '')
    .replaceAll(RegExp('[*_#`>]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// One goal in the goals list. Carries every field of `GET /goals` (the user
/// wants the list itself to answer "what are my goals"); tap opens the detail.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal, required this.onTap});

  final Goal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = plainPreview(goal.description);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: goal.isActive ? scheme.primary : scheme.outline,
          width: goal.isActive ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.name.isNotEmpty ? goal.name : l10n.untitledGoal,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (goal.isActive) const ActiveGoalBadge(),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.elo} ${goal.currentElo}',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: scheme.secondary),
              ),
              const SizedBox(height: 8),
              Text(
                preview.isNotEmpty ? preview : l10n.noDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              GoalDates(goal: goal),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Created …  ·  Updated …".
class GoalDates extends StatelessWidget {
  const GoalDates({super.key, required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Text(
      '${l10n.goalCreatedOn(formatGoalDate(context, goal.createdAt))}'
      '  ·  ${l10n.goalUpdatedOn(formatGoalDate(context, goal.updatedAt))}',
      style: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

class ActiveGoalBadge extends StatelessWidget {
  const ActiveGoalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final success =
        Theme.of(context).extension<CustomColors>()?.success ?? Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: success.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppLocalizations.of(context).activeGoalBadge,
        style: TextStyle(
          color: success,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
