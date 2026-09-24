import 'package:flutter/material.dart';

import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/stat_data.dart';

/// Typed arguments passed via go_router's `extra` for routes that need rich
/// objects (not deep-linkable; `extra` is not preserved across a web refresh).

/// Args for the goal-questions onboarding step.
class GoalQuestionsArgs {
  final String prompt;
  final List<ObjectiveQuestion> questions;

  const GoalQuestionsArgs({required this.prompt, required this.questions});
}

/// Args for the lesson finish screen (computed stats from the completed lesson).
class FinishLessonArgs {
  final String title;
  final IconData icon;
  final StatData timeSpent;
  final StatData accuracy;
  final StatData elo;

  const FinishLessonArgs({
    required this.title,
    required this.icon,
    required this.timeSpent,
    required this.accuracy,
    required this.elo,
  });
}
