import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/features/home/domain/home_dashboard.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// The user's most recent lessons for the active goal. Each row shows accuracy,
/// time taken and the day it was done. Capped so the dashboard fits the screen.
///
/// The elo badge that used to close each row is gone with the per-lesson
/// rating change (#131); the day takes its place until #62 gives the rating a
/// history again.
class RecentLessonsList extends StatelessWidget {
  final List<RecentLesson> lessons;

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
          AppLocalizations.of(context).recentLessons,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10.0),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              AppLocalizations.of(context).noLessonsYet,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
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
  final RecentLesson lesson;

  const _RecentLessonRow({required this.lesson});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
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
          Text(
            DateFormat.MMMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(lesson.date),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
