import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_goal_draft.g.dart';

/// The draft being committed, held from the moment the student confirms the
/// study plan until `POST /goals` succeeds. Creating a goal needs a session:
/// when there is none (or it expires mid-call and the API client routes to the
/// start screen), the sign-in brings the student back to this draft instead of
/// making them answer everything again. In memory only: a reload loses it.
@Riverpod(keepAlive: true)
class PendingGoalDraft extends _$PendingGoalDraft {
  @override
  GoalDraft? build() => null;

  void hold(GoalDraft draft) => state = draft;

  void clear() => state = null;
}
