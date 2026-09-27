import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_plan_controller.g.dart';

/// Where committing the study plan is. Every outcome is a new instance, so a
/// second failure after a retry is a change the screen hears.
sealed class StudyPlanState {}

/// Shown, not yet confirmed.
final class PlanShown extends StudyPlanState {}

/// `POST /goals` is in flight.
final class PlanCommitting extends StudyPlanState {}

/// There is no session, or it ended mid-call: the draft is held and the
/// student signs in, which brings him back to it (`SignInLanding`).
final class PlanNeedsSignIn extends StudyPlanState {}

/// The goal exists and is the active one: [goal] carries the standard
/// questions to ask while its first lesson generates (#132).
final class PlanCommitted extends StudyPlanState {
  PlanCommitted(this.goal);

  final CreatedGoal goal;
}

/// `POST /goals` failed; the plan is untouched, so a retry sends it again.
final class PlanCommitFailed extends StudyPlanState {
  PlanCommitFailed(this.error);

  final Object error;
}

/// Step 3 of goal creation: confirming [draft] creates the goal, or starting
/// over drops it.
///
/// `POST /goals` needs a session. The draft is held (`PendingGoalDraft`) from
/// the moment he confirms until the goal exists, so a detour to the sign-in
/// screen — none to begin with, or a 401 the client could not refresh — loses
/// nothing he said.
@riverpod
class StudyPlanController extends _$StudyPlanController {
  @override
  StudyPlanState build(GoalDraft draft) => PlanShown();

  Future<void> confirm() async {
    if (state is PlanCommitting) return;
    final pending = ref.read(pendingGoalDraftProvider.notifier)..hold(draft);
    if (!ref.read(authServiceProvider).isSignedIn()) {
      state = PlanNeedsSignIn();
      return;
    }
    // Read before the call: the goal is stored as active even if the screen
    // is gone by the time it exists.
    final storage = ref.read(settingsStorageProvider);
    state = PlanCommitting();
    try {
      final created = await ref.read(onboardingApiProvider).create(draft);
      await storage.writeCurrentGoalId(created.id);
      pending.clear();
      if (ref.mounted) state = PlanCommitted(created);
    } on ApiException catch (e) {
      // The plan is open to visitors, so the router leaves him here after a
      // 401 that ended the session: he goes to sign in as if he had none.
      if (ref.mounted) {
        state = e.status == 401 ? PlanNeedsSignIn() : PlanCommitFailed(e);
      }
    } on Exception catch (e) {
      if (ref.mounted) state = PlanCommitFailed(e);
    }
  }

  /// Drops the draft: the student writes a new prompt.
  void startOver() => ref.read(pendingGoalDraftProvider.notifier).clear();
}
