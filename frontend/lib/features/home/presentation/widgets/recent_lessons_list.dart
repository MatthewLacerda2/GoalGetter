import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/features/home/debug/mock_home_screen.dart';

/// The user's most recent lessons for the active goal. Each row shows accuracy,
/// time taken, and an elo badge (green = gained, grey = even, blue = lost).
/// Capped so the dashboard fits the screen.
class RecentLessonsList extends StatelessWidget {
  final List<MockRecentLesson> lessons;

  /// Max rows to display (keeps the dashboard compact).
  static const _maxRows = 4;

  const RecentLessonsList({super.key, required this.lessons});

  @override
  Widget build(BuildContext context) {
    final shown = lessons.take(_maxRows).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.recentLessons,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10.0),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              AppLocalizations.of(context)!.noLessonsYet,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  _RecentLessonRow(lesson: shown[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _RecentLessonRow extends StatelessWidget {
  final MockRecentLesson lesson;

  const _RecentLessonRow({required this.lesson});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Text(
            '${lesson.accuracy.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(width: 12.0),
          Icon(
            Icons.schedule,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3.0),
          Text(
            _formatTime(lesson.durationSeconds),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          _EloBadge(delta: lesson.eloDelta),
        ],
      ),
    );
  }
}

/// Elo delta pill: green if gained, grey if even, blue if lost.
class _EloBadge extends StatelessWidget {
  final int delta;

  const _EloBadge({required this.delta});

  @override
  Widget build(BuildContext context) {
    final custom = Theme.of(context).extension<CustomColors>();
    final Color color;
    if (delta > 0) {
      color = custom?.success ?? Colors.green;
    } else if (delta < 0) {
      color = custom?.lost ?? Colors.blue;
    } else {
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    }
    final label = delta > 0 ? '+$delta' : '$delta';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
