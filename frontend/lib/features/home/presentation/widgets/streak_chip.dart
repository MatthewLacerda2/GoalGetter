import 'package:flutter/material.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// Streak indicator (top-right of Home): a flame pill with the current streak
/// count — the counterpart to the elo chip on the left. The streak is a
/// user-wide, Duolingo-style return mechanic, independent of the active goal.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final orange = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: orange, size: 18),
          const SizedBox(width: 6.0),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
