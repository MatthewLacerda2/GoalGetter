import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/startup/app_start_controller.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_landing.g.dart';

/// A route to go to, and the `extra` it needs.
typedef Landing = ({String location, Object? extra});

/// Where a fresh sign-in lands: back on the study plan when the student was
/// committing a goal (the draft is held), else wherever a launch would go.
class SignInLanding {
  const SignInLanding({
    required GoalDraft? heldDraft,
    required AppStartController appStart,
  }) : _heldDraft = heldDraft,
       _appStart = appStart;

  final GoalDraft? _heldDraft;
  final AppStartController _appStart;

  Future<Landing> resolve() async {
    final draft = _heldDraft;
    if (draft != null) return (location: AppRoutes.studyPlan, extra: draft);
    final result = await _appStart.evaluate();
    return (location: result.destination.location, extra: null);
  }
}

@riverpod
SignInLanding signInLanding(Ref ref) => SignInLanding(
  heldDraft: ref.watch(pendingGoalDraftProvider),
  appStart: ref.watch(appStartControllerProvider),
);
