import 'package:flutter/material.dart';

import 'package:goal_getter/core/theme/app_theme.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';

/// The description without its markdown marks, for a one-glance preview.
String plainPreview(String markdown) => markdown
    .replaceAll(RegExp(r'^\s*([-+]|\d+\.)\s+', multiLine: true), '')
    .replaceAll(RegExp('[*_#`>]'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// One goal in the goals list: name, rating and a preview of the description
/// (the list itself answers "what are my goals"); tap opens the detail.
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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(
          color: goal.isActive ? scheme.primary : scheme.outline,
          width: goal.isActive ? AppStroke.thick : AppStroke.hairline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${l10n.elo} ${goal.currentElo}',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: scheme.secondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                preview.isNotEmpty ? preview : l10n.noDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActiveGoalBadge extends StatelessWidget {
  const ActiveGoalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final success =
        CustomColors.of(context).success;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: success.withValues(alpha: AppOpacity.tint),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text(
        AppLocalizations.of(context).activeGoalBadge,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: success,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
