import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/features/lessons/presentation/screens/lesson_screen.dart';

/// Primary call-to-action on the Home screen: starts the daily lesson.
///
/// Launches [LessonScreen] with no questions, so the lesson controller fetches
/// a fresh activity for the active goal.
class StartLessonButton extends StatelessWidget {
  const StartLessonButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LessonScreen()),
          );
        },
        icon: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
        label: Text(
          AppLocalizations.of(context)!.startLesson,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 18.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
    );
  }
}
