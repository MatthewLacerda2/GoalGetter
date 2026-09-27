import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/question_timer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'goal_questions_controller.g.dart';

/// Where the request for the study plan is.
sealed class PlanRequest {}

/// Not sent: the student is still answering, or is back from the plan.
final class PlanNotAsked extends PlanRequest {}

/// Sent with every answer; the plan is being written.
final class PlanLoading extends PlanRequest {}

/// The plan came back: [draft] is everything the plan screen shows.
final class PlanReady extends PlanRequest {
  PlanReady(this.draft);

  final GoalDraft draft;
}

/// The request failed. Every answer is kept, so a retry sends the same ones.
final class PlanFailed extends PlanRequest {
  PlanFailed(this.error);

  final Object error;
}

/// Step 2 of goal creation: which question is on screen, what was picked for
/// each, and the study-plan request the last answer sends.
final class GoalQuestionsState {
  const GoalQuestionsState({
    required this.index,
    required this.answers,
    required this.plan,
  });

  /// The question on screen.
  final int index;

  /// The option picked for each question, null until one is.
  final List<String?> answers;

  final PlanRequest plan;

  bool get isLast => index == answers.length - 1;

  GoalQuestionsState copyWith({
    int? index,
    List<String?>? answers,
    PlanRequest? plan,
  }) => GoalQuestionsState(
    index: index ?? this.index,
    answers: answers ?? this.answers,
    plan: plan ?? this.plan,
  );
}

/// The objective questions Gemini wrote for [prompt], one at a time. The
/// screen owns how a question arrives (the slide, the pause that shows the
/// pick); this owns what was answered and how long each question took, and
/// sends them all to `POST /goals/study-plan`.
@riverpod
class GoalQuestionsController extends _$GoalQuestionsController {
  late QuestionTimer _timer;

  @override
  GoalQuestionsState build(String prompt, List<ObjectiveQuestion> questions) {
    _timer = QuestionTimer(questions.length)..show(0);
    return GoalQuestionsState(
      index: 0,
      answers: List.filled(questions.length, null),
      plan: PlanNotAsked(),
    );
  }

  /// [option] answers the question on screen, and its clock stops. False
  /// while the plan is being written: the answers are already sent.
  bool select(String option) {
    if (state.plan is PlanLoading) return false;
    _timer.stop();
    state = state.copyWith(answers: [...state.answers]..[state.index] = option);
    return true;
  }

  /// The question on screen is being left: its clock stops before the slide,
  /// which is time on no question.
  void leave() => _timer.stop();

  /// The question [step] away takes the screen, and its clock runs.
  void move(int step) {
    final index = state.index + step;
    state = state.copyWith(index: index);
    _timer.show(index);
  }

  /// Back from the plan, the student is on the last question again: its clock
  /// resumes, in case he changes that answer.
  void resume() {
    state = state.copyWith(plan: PlanNotAsked());
    _timer.show(state.index);
  }

  /// Sends every answer, with the seconds each took and the model that wrote
  /// its question, for the study plan. The same answers become the draft that
  /// `POST /goals` stores.
  Future<void> requestPlan() async {
    state = state.copyWith(plan: PlanLoading());
    final answers = [
      for (var i = 0; i < questions.length; i++)
        ObjectiveAnswer(
          question: questions[i].question,
          answer: state.answers[i] ?? '',
          totalSeconds: _timer.secondsOn(i),
          aiModel: questions[i].aiModel,
        ),
    ];
    try {
      final plan = await ref
          .read(onboardingApiProvider)
          .studyPlan(prompt, answers);
      if (!ref.mounted) return;
      final draft = GoalDraft(prompt: prompt, answers: answers, plan: plan);
      state = state.copyWith(plan: PlanReady(draft));
    } on Exception catch (e) {
      if (ref.mounted) state = state.copyWith(plan: PlanFailed(e));
    }
  }
}
