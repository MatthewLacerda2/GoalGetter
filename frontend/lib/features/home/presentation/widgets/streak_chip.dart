import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/features/lessons/presentation/controllers/streak_controller.dart';

/// Streak indicator (top-right of Home): a flame pill with the current streak
/// count — the counterpart to the elo chip on the left. The streak is a
/// user-wide, Duolingo-style return mechanic, independent of the active goal.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final count = streakAsync.maybeWhen(
      data: (data) => data.currentStreak as int,
      orElse: () => 0,
    );
    final orange = Theme.of(context).colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: orange, size: 18),
          const SizedBox(width: 6.0),
          Text(
            '$count',
            style: TextStyle(
              color: orange,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
