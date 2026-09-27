import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';

/// Typed arguments passed via go_router's `extra` for routes that need rich
/// objects (not deep-linkable; `extra` is not preserved across a web refresh).

/// Args for the goal-questions onboarding step.
class GoalQuestionsArgs {
  final String prompt;
  final List<ObjectiveQuestion> questions;

  const GoalQuestionsArgs({required this.prompt, required this.questions});
}

/// Args for the standard questions asked while the first lesson generates:
/// the goal they belong to, and the questions `POST /goals` answered
/// with.
class StandardQuestionsArgs {
  final String goalId;
  final List<StandardQuestion> questions;

  const StandardQuestionsArgs({required this.goalId, required this.questions});
}
