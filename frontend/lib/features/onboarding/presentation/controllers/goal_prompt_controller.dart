import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'goal_prompt_controller.g.dart';

/// Where step 1 of goal creation is: what the student typed, sent to
/// `POST /goals/objective-questions`.
///
/// Every outcome is a new instance, never a `const` one, so the same outcome
/// twice — two taps on a prompt that is still too short — is two changes the
/// screen hears.
sealed class GoalPromptState {}

/// Nothing sent yet.
final class PromptIdle extends GoalPromptState {}

/// Too short to be worth a call: the student is asked for more detail.
final class PromptTooShort extends GoalPromptState {}

/// The call is in flight.
final class PromptAsking extends GoalPromptState {}

/// Gemini wrote the questions for [prompt]: they are the next step.
final class PromptAccepted extends GoalPromptState {
  PromptAccepted(this.prompt, this.questions);

  final String prompt;
  final List<ObjectiveQuestion> questions;
}

/// The call failed. The prompt is still in the field, so a retry sends it
/// again.
final class PromptFailed extends GoalPromptState {
  PromptFailed(this.error);

  final Object error;

  /// Gemini saying the prompt is not a goal: its `detail` is its reasoning,
  /// and the prompt wants rephrasing, not the same request again.
  bool get rejected => switch (error) {
    ApiException(code: ErrorCode.notAGoal) => true,
    _ => false,
  };
}

@riverpod
class GoalPromptController extends _$GoalPromptController {
  /// Fewer characters than this say too little to write questions about.
  static const minPromptLength = 16;

  @override
  GoalPromptState build() => PromptIdle();

  /// Sends [typed], trimmed, unless it is too short or a call is in flight.
  Future<void> ask(String typed) async {
    if (state is PromptAsking) return;
    final prompt = typed.trim();
    if (prompt.length < minPromptLength) {
      state = PromptTooShort();
      return;
    }
    state = PromptAsking();
    try {
      final questions = await ref
          .read(onboardingApiProvider)
          .objectiveQuestions(prompt);
      if (ref.mounted) state = PromptAccepted(prompt, questions);
    } on Exception catch (e) {
      if (ref.mounted) state = PromptFailed(e);
    }
  }
}
