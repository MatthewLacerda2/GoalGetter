import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/home/presentation/controllers/home_controller.dart';
import 'package:goal_getter/features/lessons/data/lessons_api.dart';
import 'package:goal_getter/features/lessons/domain/lesson_models.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/lesson_state.dart';
import 'package:goal_getter/features/profile/presentation/controllers/profile_controller.dart';

export 'package:goal_getter/features/lessons/presentation/controllers/lesson_state.dart';

part 'lesson_controller.g.dart';

/// Runs one lesson on the active goal: open it, answer each question once
/// (graded inline for feedback), submit those answers as one batch, then a
/// review round of the wrong ones that is never submitted.
///
/// The batch is what the backend marks as a lesson, so it is sent whole and in
/// order, once - see [_resumeAt] and `_hasSubmittedAnswers`.
@riverpod
class LessonController extends _$LessonController {
  @override
  LessonState build() {
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });
    return const LessonState();
  }

  Timer? _timer;
  DateTime _startTime = DateTime.now();
  bool _disposed = false;
  String? _goalId;
  bool _hasSubmittedAnswers = false;

  /// Opens a new lesson; also the retry after a failed start.
  Future<void> start() async {
    _timer?.cancel();
    _hasSubmittedAnswers = false;
    state = const LessonState(isLoading: true);

    final goalId = ref.read(settingsStorageProvider).readCurrentGoalId();
    if (goalId == null || goalId.isEmpty) {
      state = const LessonState(
        isLoading: false,
        startFailure: LessonFailure(LessonStartFailureKind.noActiveGoal),
      );
      return;
    }

    final LessonSession session;
    try {
      session = await ref.read(lessonsApiProvider).start(goalId);
    } on ApiException catch (e) {
      if (_disposed) return;
      final kind = e.status == LessonsApi.notReadyStatus
          ? LessonStartFailureKind.notReady
          : LessonStartFailureKind.failed;
      state = LessonState(isLoading: false, startFailure: LessonFailure(kind, e));
      return;
    } on Exception catch (e) {
      if (_disposed) return;
      state = LessonState(
        isLoading: false,
        startFailure: LessonFailure(LessonStartFailureKind.failed, e),
      );
      return;
    }
    if (_disposed) return;
    if (session.questions.isEmpty) {
      // The backend answers 409 for an empty bank; treat an empty 201 the same.
      state = const LessonState(
        isLoading: false,
        startFailure: LessonFailure(LessonStartFailureKind.notReady),
      );
      return;
    }

    _goalId = goalId;
    _startTime = DateTime.now();
    _startTimer();
    state = LessonState(
      isLoading: false,
      questions: [
        for (final (i, q) in session.questions.indexed)
          LessonQuestionState(apiQuestion: q, startTime: i == 0 ? _startTime : null),
      ],
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(totalTimeSpent: DateTime.now().difference(_startTime));
    });
  }

  void selectChoice(int index) {
    if (!state.isAnswerRevealed) {
      state = state.copyWith(selectedChoiceIndex: index);
    }
  }

  void submitAnswer() {
    final selected = state.selectedChoiceIndex;
    if (selected == null) return;

    final currentIdx = state.currentQuestionIndex;
    final currentQuestion = state.questions[currentIdx];
    final startedAt = currentQuestion.startTime;
    final secondsSpent = startedAt == null
        ? 2
        : DateTime.now().difference(startedAt).inSeconds.clamp(2, 3600);

    final isCorrect = selected == currentQuestion.apiQuestion.correctAnswerIndex;
    final updatedQuestions = List<LessonQuestionState>.from(state.questions);
    updatedQuestions[currentIdx] = currentQuestion.copyWith(
      status: isCorrect ? LessonQuestionStatus.correct : LessonQuestionStatus.incorrect,
      studentAnswerIndex: selected,
      secondsSpent: secondsSpent,
    );

    state = state.copyWith(questions: updatedQuestions, isAnswerRevealed: true);
  }

  Future<void> nextQuestion() async {
    final currentIdx = state.currentQuestionIndex;
    if (currentIdx < state.questions.length - 1) {
      final updatedQuestions = List<LessonQuestionState>.from(state.questions);
      updatedQuestions[currentIdx + 1] =
          updatedQuestions[currentIdx + 1].copyWith(startTime: DateTime.now());

      state = state.copyWith(
        questions: updatedQuestions,
        currentQuestionIndex: currentIdx + 1,
        clearSelection: true,
        isAnswerRevealed: false,
      );
    } else if (!state.isReviewMode && !_hasSubmittedAnswers) {
      await _submitEvaluation();
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }

  /// Sends the answers again after a failed submit. They were kept in state.
  Future<void> retrySubmit() => _submitEvaluation();

  /// Puts the student back on question [index], its clock restarted.
  ///
  /// The backend takes whatever comes, so a gap would simply be a lesson the
  /// student was credited less for than he did. It is returned to instead of
  /// sent. The screen does not let one open - a question is answered before
  /// the next is shown - and this keeps that true of the controller itself.
  void _resumeAt(int index) {
    final questions = List<LessonQuestionState>.from(state.questions);
    questions[index] = questions[index].copyWith(startTime: DateTime.now());
    state = state.copyWith(
      questions: questions,
      currentQuestionIndex: index,
      clearSelection: true,
      isAnswerRevealed: false,
    );
  }

  Future<void> _submitEvaluation() async {
    if (state.isSubmitting || _hasSubmittedAnswers) return;
    final unanswered = state.questions.indexWhere((q) => !q.isAnswered);
    if (unanswered != -1) {
      _resumeAt(unanswered);
      return;
    }
    final answers = [
      for (final q in state.questions)
        LessonAnswer(
          questionId: q.apiQuestion.id,
          choiceIndex: q.studentAnswerIndex!,
          secondsSpent: q.secondsSpent!,
        ),
    ];
    state = state.copyWith(isSubmitting: true, clearSubmitFailure: true);

    try {
      final evaluation = await ref
          .read(lessonsApiProvider)
          .submit(_goalId!, answers);
      if (!_disposed) _finish(evaluation);
    } on Exception catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isSubmitting: false,
        submitFailure: LessonFailure(null, e),
      );
    }
  }

  void _finish(LessonEvaluation evaluation) {
    _hasSubmittedAnswers = true;
    _timer?.cancel();
    // Home's rating, streak and recent lessons, and Profile's streak, moved.
    ref.invalidate(homeControllerProvider);
    ref.invalidate(profileControllerProvider);
    state = state.copyWith(
      evaluationResponse: evaluation,
      isSubmitting: false,
      isCompleted: true,
    );
  }

  void startReviewMode(List<LessonQuestionState> incorrectQuestions) {
    final now = DateTime.now();
    state = state.copyWith(
      questions: [
        for (final (i, q) in incorrectQuestions.indexed)
          LessonQuestionState(apiQuestion: q.apiQuestion, startTime: i == 0 ? now : null),
      ],
      currentQuestionIndex: 0,
      clearSelection: true,
      isAnswerRevealed: false,
      isReviewMode: true,
      isCompleted: false,
    );
  }
}
