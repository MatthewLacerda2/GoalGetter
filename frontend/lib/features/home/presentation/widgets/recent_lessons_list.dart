import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/features/home/domain/home_dashboard.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';
import 'package:goal_getter/core/widgets/lesson_clock.dart';

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
        const SizedBox(height: AppSpacing.gap10),
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
                      height: AppStroke.hairline,
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
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.schedule,
            size: AppIconSize.xs,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.gap3),
          Text(
            formatLessonClock(Duration(seconds: lesson.durationSeconds)),
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
