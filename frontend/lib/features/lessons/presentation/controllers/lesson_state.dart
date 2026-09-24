import 'package:goal_getter/features/lessons/domain/lesson_models.dart';

/// One question of the running lesson, with the student's attempt at it.
class LessonQuestionState {
  final MultipleChoiceQuestion apiQuestion;
  final LessonQuestionStatus status;
  final DateTime? startTime;
  final int? studentAnswerIndex;
  final int? secondsSpent;

  const LessonQuestionState({
    required this.apiQuestion,
    this.status = LessonQuestionStatus.notAnswered,
    this.startTime,
    this.studentAnswerIndex,
    this.secondsSpent,
  });

  bool get isAnswered => studentAnswerIndex != null && secondsSpent != null;

  LessonQuestionState copyWith({
    LessonQuestionStatus? status,
    DateTime? startTime,
    int? studentAnswerIndex,
    int? secondsSpent,
  }) {
    return LessonQuestionState(
      apiQuestion: apiQuestion,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      studentAnswerIndex: studentAnswerIndex ?? this.studentAnswerIndex,
      secondsSpent: secondsSpent ?? this.secondsSpent,
    );
  }
}

/// Why a lesson could not start.
enum LessonStartFailureKind {
  /// 409 from the backend: the goal's question bank is still empty.
  notReady,

  /// No active goal id on the device.
  noActiveGoal,

  /// Anything else; retryable.
  failed,
}

/// A failed call, as the screen shows it. [cause] is what the call threw, or
/// null when there was nothing to throw; the screen turns it into a sentence.
class LessonFailure<K> {
  final K kind;
  final Object? cause;

  const LessonFailure(this.kind, [this.cause]);
}

class LessonState {
  final List<LessonQuestionState> questions;
  final int currentQuestionIndex;
  final int? selectedChoiceIndex;
  final bool isAnswerRevealed;
  final bool isReviewMode;

  /// Opening the lesson (POST /goals/{id}/lessons).
  final bool isLoading;
  final LessonFailure<LessonStartFailureKind>? startFailure;

  /// Sending the first attempts. A failure keeps [questions] untouched, so a
  /// retry sends the same answers.
  final bool isSubmitting;
  final LessonFailure<void>? submitFailure;

  final Duration totalTimeSpent;
  final LessonEvaluation? evaluationResponse;
  final bool isCompleted;

  const LessonState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.selectedChoiceIndex,
    this.isAnswerRevealed = false,
    this.isReviewMode = false,
    this.isLoading = true,
    this.startFailure,
    this.isSubmitting = false,
    this.submitFailure,
    this.totalTimeSpent = Duration.zero,
    this.evaluationResponse,
    this.isCompleted = false,
  });

  /// Nullable fields keep their value unless replaced; the `clear*` flags null
  /// them. (The old copyWith nulled the selection on every call, so the 1 s
  /// timer tick wiped the student's choice.)
  LessonState copyWith({
    List<LessonQuestionState>? questions,
    int? currentQuestionIndex,
    int? selectedChoiceIndex,
    bool clearSelection = false,
    bool? isAnswerRevealed,
    bool? isReviewMode,
    bool? isSubmitting,
    LessonFailure<void>? submitFailure,
    bool clearSubmitFailure = false,
    Duration? totalTimeSpent,
    LessonEvaluation? evaluationResponse,
    bool? isCompleted,
  }) {
    return LessonState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedChoiceIndex: clearSelection
          ? null
          : selectedChoiceIndex ?? this.selectedChoiceIndex,
      isAnswerRevealed: isAnswerRevealed ?? this.isAnswerRevealed,
      isReviewMode: isReviewMode ?? this.isReviewMode,
      isLoading: false,
      startFailure: startFailure,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitFailure: clearSubmitFailure
          ? null
          : submitFailure ?? this.submitFailure,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      evaluationResponse: evaluationResponse ?? this.evaluationResponse,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
