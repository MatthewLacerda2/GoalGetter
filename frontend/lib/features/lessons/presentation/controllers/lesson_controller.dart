import 'package:clock/clock.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/features/home/presentation/controllers/home_controller.dart';
import 'package:goal_getter/features/lessons/data/lessons_api.dart';
import 'package:goal_getter/features/lessons/domain/lesson_models.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/lesson_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:goal_getter/features/lessons/presentation/controllers/lesson_state.dart';

part 'lesson_controller.g.dart';

/// Runs one lesson on the active goal: open it, answer each question once
/// (graded inline for feedback), submit those answers as one batch, then
/// review rounds of the wrong ones - never submitted - until every one of them
/// has been answered right.
///
/// The batch is what the backend marks as a lesson, so it is sent whole and in
/// order, once: only a [FirstRound] is ever submitted, and a gap in it is
/// returned to rather than sent.
///
/// Every decision about the lesson's flow is taken here; the screen draws the
/// [LessonState] it is handed. Time is read from `package:clock`, so a test
/// decides how long a question was on screen.
///
/// Opening is [build]: the screen watching the provider opens a lesson on the
/// active goal ([activeGoalProvider], the goal Home and the Tutor are on too),
/// and `ref.invalidate` opens a new one - the retry after a failed start.
@riverpod
class LessonController extends _$LessonController {
  /// The goal the lesson was opened on, which its answers are sent to.
  late String _goalId;

  @override
  Future<LessonState> build() async {
    final goalId = ref.watch(activeGoalProvider);
    if (goalId == null) return const LessonNoActiveGoal();
    final LessonSession session;
    try {
      session = await ref.read(lessonsApiProvider).start(goalId);
    } on ApiException catch (e) {
      if (e.code == ErrorCode.lessonsNotReady) return const LessonNotReady();
      rethrow;
    }
    // The backend answers 409 for an empty bank; treat an empty 201 the same.
    if (session.questions.isEmpty) return const LessonNotReady();
    _goalId = goalId;
    return LessonAnswering.start(
      const FirstRound(),
      session.questions,
      clock.now(),
    );
  }

  /// The question on screen, when one is.
  LessonAnswering? get _answering => switch (state) {
    AsyncData(value: final LessonAnswering answering) => answering,
    _ => null,
  };

  void selectChoice(int index) {
    final answering = _answering;
    if (answering == null || answering.isRevealed) return;
    state = AsyncData(answering.withPick(index));
  }

  /// Enters the tapped choice: the question is graded on screen, and the time
  /// it was up is what the backend records for it (at least 2 s, at most an
  /// hour).
  void submitAnswer() {
    final answering = _answering;
    final choice = answering?.pick;
    if (answering == null || choice == null || answering.isRevealed) return;
    final shownAt = answering.current.shownAt;
    final seconds = shownAt == null
        ? 2
        : clock.now().difference(shownAt).inSeconds.clamp(2, 3600);
    state = AsyncData(
      answering.enter(LessonAttempt(choice: choice, secondsSpent: seconds)),
    );
  }

  /// Past an entered question: the next one, the submit at the end of the
  /// first round, or what follows a review round.
  Future<void> nextQuestion() async {
    final answering = _answering;
    if (answering == null || !answering.isRevealed) return;
    if (!answering.isLast) {
      state = AsyncData(answering.show(answering.index + 1, clock.now()));
      return;
    }
    switch (answering.round) {
      case FirstRound():
        await _submit(answering);
      case ReviewRound(:final evaluation):
        // A review round ends only when he gets every one right: the ones he
        // missed again come back, round after round (the user, 2026-09-26).
        final missed = answering.missed;
        state = AsyncData(
          missed.isEmpty
              ? LessonFinished(evaluation)
              : LessonAnswering.start(
                  ReviewRound(evaluation),
                  missed,
                  clock.now(),
                ),
        );
    }
  }

  /// Sends the answers again after a failed submit. They were kept in state.
  Future<void> retrySubmit() async {
    final answering = _answering;
    if (answering != null && answering.round is FirstRound) {
      await _submit(answering);
    }
  }

  /// From the screen that announces it, into the first review round.
  void startReview() {
    if (state case AsyncData(
      value: LessonReviewIntro(:final missed, :final evaluation),
    )) {
      state = AsyncData(
        LessonAnswering.start(ReviewRound(evaluation), missed, clock.now()),
      );
    }
  }

  Future<void> _submit(LessonAnswering answering) async {
    // The backend takes whatever comes, so a gap would simply be a lesson the
    // student was credited less for than he did. It is returned to instead of
    // sent. The screen does not let one open - a question is answered before
    // the next is shown - and this keeps that true of the controller itself.
    final gap = answering.questions.indexWhere((q) => q.attempt == null);
    if (gap != -1) {
      state = AsyncData(answering.show(gap, clock.now()));
      return;
    }
    final answers = [
      for (final q in answering.questions)
        LessonAnswer(
          questionId: q.question.id,
          choiceIndex: q.attempt!.choice,
          secondsSpent: q.attempt!.secondsSpent,
        ),
    ];
    state = const AsyncData(LessonSubmitting());
    // This build's ref: unmounted once the provider is disposed or rebuilt,
    // so a late answer never lands on a lesson that is no longer this one.
    final opened = ref;
    try {
      final evaluation = await opened
          .read(lessonsApiProvider)
          .submit(_goalId, answers);
      if (!opened.mounted) return;
      // Home's rating, streak and recent lessons moved.
      opened.invalidate(homeControllerProvider);
      final missed = answering.missed;
      state = AsyncData(
        missed.isEmpty
            ? LessonFinished(evaluation)
            : LessonReviewIntro(missed: missed, evaluation: evaluation),
      );
    } on Exception catch (e) {
      if (!opened.mounted) return;
      state = AsyncData(answering.withRound(FirstRound(submitFailure: e)));
    }
  }
}
