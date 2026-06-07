import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/streak_controller.dart';
import 'package:goal_getter/features/lessons/presentation/screens/streak_screen.dart';

/// Compact streak indicator shown in the top-right of the Home screen.
///
/// Tapping it opens the full [StreakScreen]. The streak is user-wide (a
/// Duolingo-style return mechanic), so it is independent of the active goal.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);
    final count = streakAsync.maybeWhen(
      data: (data) => data.currentStreak as int,
      orElse: () => 0,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(20.0),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StreakScreen(
              descriptionText: AppLocalizations.of(context)!.keepThePressureOn,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              color: Theme.of(context).colorScheme.secondary,
              size: 22,
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
        ),
      ),
    );
  }
}
