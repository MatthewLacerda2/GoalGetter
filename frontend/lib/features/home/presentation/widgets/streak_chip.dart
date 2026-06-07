import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/features/lessons/presentation/controllers/streak_controller.dart';

/// Streak indicator in the top-right of the Home screen: a flame icon and the
/// current streak count. Purely informational (not interactive, no background).
/// The streak is a user-wide, Duolingo-style return mechanic, independent of the
/// active goal.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final count = streakAsync.maybeWhen(
      data: (data) => data.currentStreak as int,
      orElse: () => 0,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.local_fire_department,
          color: Theme.of(context).colorScheme.secondary,
          size: 26,
        ),
        const SizedBox(width: 6.0),
        Text(
          '$count',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
