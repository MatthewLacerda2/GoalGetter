import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/features/home/debug/mock_home_screen.dart';

/// Shows the user's most recent lessons for the active goal: accuracy plus the
/// elo gained or lost (chess.com / lichess style).
class RecentLessonsList extends StatelessWidget {
  final List<MockRecentLesson> lessons;

  const RecentLessonsList({super.key, required this.lessons});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.recentLessons,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12.0),
        if (lessons.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              AppLocalizations.of(context)!.noLessonsYet,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14.0,
              ),
            ),
          )
        else
          ...lessons.map((lesson) => _RecentLessonTile(lesson: lesson)),
      ],
    );
  }
}

class _RecentLessonTile extends StatelessWidget {
  final MockRecentLesson lesson;

  const _RecentLessonTile({required this.lesson});

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isGain = lesson.eloDelta >= 0;
    final successColor =
        Theme.of(context).extension<CustomColors>()?.success ?? Colors.green;
    final deltaColor = isGain ? successColor : Theme.of(context).colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          Text(
            _formatDate(lesson.date),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              '${lesson.accuracy.toStringAsFixed(0)}%',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            isGain ? Icons.arrow_upward : Icons.arrow_downward,
            color: deltaColor,
            size: 16,
          ),
          const SizedBox(width: 2.0),
          Text(
            '${isGain ? '+' : ''}${lesson.eloDelta}',
            style: TextStyle(
              color: deltaColor,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
