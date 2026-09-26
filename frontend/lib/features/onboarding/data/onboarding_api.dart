import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_providers.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/domain/study_plan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_api.g.dart';

/// The goal-creation calls. The first three reach Gemini on the backend, so a
/// Gemini failure keeps Gemini's status code (429, 503...), and they are
/// rate-limited to 20/min per client. The first two are public; `create` and
/// `sendStandardAnswers` need a session.
class OnboardingApi {
  OnboardingApi(this._api);

  final ApiClient _api;

  /// A 400 means Gemini judged [prompt] not to be a goal: its `detail` is
  /// Gemini's reasoning, meant for the student.
  Future<List<ObjectiveQuestion>> objectiveQuestions(String prompt) async {
    final body =
        await _api.post('/goals/objective-questions', body: {'prompt': prompt})
            as List;
    return body
        .map((e) => ObjectiveQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudyPlan> studyPlan(
    String prompt,
    List<ObjectiveAnswer> answers,
  ) async {
    final body = await _api.post(
      '/goals/study-plan',
      body: {
        'prompt': prompt,
        'answers': answers.map((a) => a.toJson()).toList(),
      },
    );
    return StudyPlan.fromJson(body as Map<String, dynamic>);
  }

  /// Creates the goal and makes it the student's active one.
  Future<CreatedGoal> create(GoalDraft draft) async {
    final body = await _api.post(
      '/goals',
      body: {
        'prompt': draft.prompt,
        'answers': draft.answers.map((a) => a.toJson()).toList(),
        'goal_name': draft.plan.goalName,
        'description': draft.plan.description,
      },
    );
    return CreatedGoal.fromJson(body as Map<String, dynamic>);
  }

  /// What the student told us about himself while his first lesson generated
  /// (#132). No Gemini, nothing waiting on it: the caller does not await it and
  /// a failure costs one fact about him, never his lesson.
  Future<void> sendStandardAnswers(
    String goalId,
    List<StandardAnswer> answers,
  ) async {
    await _api.post(
      '/goals/$goalId/standard-answers',
      body: {'answers': answers.map((a) => a.toJson()).toList()},
    );
  }
}

@riverpod
OnboardingApi onboardingApi(Ref ref) =>
    OnboardingApi(ref.watch(apiClientProvider));
