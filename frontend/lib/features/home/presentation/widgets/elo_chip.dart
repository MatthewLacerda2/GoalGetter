import 'package:flutter/material.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';

/// Compact elo (rating) pill for the top-left of the Home screen — the
/// counterpart to the streak chip on the top-right.
class EloChip extends StatelessWidget {
  final int elo;

  const EloChip({super.key, required this.elo});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: AppOpacity.faint),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: primary, size: AppIconSize.sm),
          const SizedBox(width: AppSpacing.gap6),
          Text(
            '$elo',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
