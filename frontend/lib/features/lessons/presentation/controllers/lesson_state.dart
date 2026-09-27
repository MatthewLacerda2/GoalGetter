import 'package:flutter/foundation.dart';

import 'package:goal_getter/features/lessons/domain/lesson_models.dart';

/// What the lesson screen is showing, once the lesson has been asked for.
///
/// Opening the lesson and a failure to open it are not here: they are the
/// controller's own `AsyncValue` (loading, error), so the screen reads them the
/// way it reads every other provider, and whatever the call throws lands in
/// the error with its retry.
///
/// Each state holds only what can be true of it - a submit failure only exists
/// in the first round, an evaluation only once the answers are in - so an
/// impossible screen cannot be written down. Equality is hand-written (#223):
/// a handful of small classes did not earn `freezed`, its generator and a
/// second kind of generated file, and every transition is a constructor call
/// in the controller rather than a general `copyWith`.
@immutable
sealed class LessonState {
  const LessonState();
}

/// The goal's question bank is still being generated: a 409 from the backend,
/// or a lesson that came back empty. A wait with a retry, not a failure.
final class LessonNotReady extends LessonState {
  const LessonNotReady();

  @override
  bool operator ==(Object other) => other is LessonNotReady;

  @override
  int get hashCode => (LessonNotReady).hashCode;
}

/// The student has no active goal, so there is nothing to open a lesson on.
final class LessonNoActiveGoal extends LessonState {
  const LessonNoActiveGoal();

  @override
  bool operator ==(Object other) => other is LessonNoActiveGoal;

  @override
  int get hashCode => (LessonNoActiveGoal).hashCode;
}

/// A question on screen, in the first round or in a review round.
final class LessonAnswering extends LessonState {
  const LessonAnswering({
    required this.round,
    required this.questions,
    this.index = 0,
    this.pick,
  });

  /// [round] over [questions], the first of them on screen since [now].
  factory LessonAnswering.start(
    LessonRound round,
    List<MultipleChoiceQuestion> questions,
    DateTime now,
  ) => LessonAnswering(
    round: round,
    questions: [
      for (final (i, q) in questions.indexed)
        LessonQuestionState(question: q, shownAt: i == 0 ? now : null),
    ],
  );

  final LessonRound round;
  final List<LessonQuestionState> questions;

  /// The question on screen.
  final int index;

  /// The choice he has tapped and not yet entered. Once entered it is the
  /// question's [LessonAttempt], and this is null.
  final int? pick;

  LessonQuestionState get current => questions[index];

  bool get isLast => index == questions.length - 1;

  /// Whether the question on screen has been entered, and so graded.
  bool get isRevealed => current.attempt != null;

  /// The choice the screen marks: the one entered, or the one tapped.
  int? get selectedChoice => current.attempt?.choice ?? pick;

  /// The questions answered wrong, in the order they were asked.
  List<MultipleChoiceQuestion> get missed => [
    for (final q in questions)
      if (q.attempt != null && !q.isCorrect) q.question,
  ];

  /// Question [index] on screen from [now], nothing tapped on it yet.
  LessonAnswering show(int index, DateTime now) {
    final shown = [...questions];
    shown[index] = LessonQuestionState(
      question: shown[index].question,
      shownAt: now,
      attempt: shown[index].attempt,
    );
    return LessonAnswering(round: round, questions: shown, index: index);
  }

  /// The question on screen entered as [attempt].
  LessonAnswering enter(LessonAttempt attempt) {
    final entered = [...questions];
    entered[index] = LessonQuestionState(
      question: current.question,
      shownAt: current.shownAt,
      attempt: attempt,
    );
    return LessonAnswering(round: round, questions: entered, index: index);
  }

  LessonAnswering withPick(int choice) => LessonAnswering(
    round: round,
    questions: questions,
    index: index,
    pick: choice,
  );

  LessonAnswering withRound(LessonRound round) => LessonAnswering(
    round: round,
    questions: questions,
    index: index,
    pick: pick,
  );

  @override
  bool operator ==(Object other) =>
      other is LessonAnswering &&
      other.round == round &&
      listEquals(other.questions, questions) &&
      other.index == index &&
      other.pick == pick;

  @override
  int get hashCode =>
      Object.hash(round, Object.hashAll(questions), index, pick);
}

/// The first round's answers are on their way to the server.
final class LessonSubmitting extends LessonState {
  const LessonSubmitting();

  @override
  bool operator ==(Object other) => other is LessonSubmitting;

  @override
  int get hashCode => (LessonSubmitting).hashCode;
}

/// The answers are in and some were wrong: the screen that says the mistakes
/// come next, before the first review round over [missed].
final class LessonReviewIntro extends LessonState {
  const LessonReviewIntro({required this.missed, required this.evaluation});

  final List<MultipleChoiceQuestion> missed;
  final LessonEvaluation evaluation;

  @override
  bool operator ==(Object other) =>
      other is LessonReviewIntro &&
      listEquals(other.missed, missed) &&
      identical(other.evaluation, evaluation);

  @override
  int get hashCode => Object.hash(Object.hashAll(missed), evaluation);
}

/// Every question has been answered right at least once: the lesson is over,
/// and [evaluation] is the server's result for its first round.
final class LessonFinished extends LessonState {
  const LessonFinished(this.evaluation);

  final LessonEvaluation evaluation;

  @override
  bool operator ==(Object other) =>
      other is LessonFinished && identical(other.evaluation, evaluation);

  @override
  int get hashCode => evaluation.hashCode;
}

/// Which round a [LessonAnswering] is in.
@immutable
sealed class LessonRound {
  const LessonRound();
}

/// The lesson proper: its answers are sent, whole and in order, once.
final class FirstRound extends LessonRound {
  const FirstRound({this.submitFailure});

  /// What the last submit threw; null when none failed. The answers stay on
  /// screen, so the screen says it over them and offers the retry.
  final Object? submitFailure;

  @override
  bool operator ==(Object other) =>
      other is FirstRound && other.submitFailure == submitFailure;

  @override
  int get hashCode => Object.hash(FirstRound, submitFailure);
}

/// A round over the questions he missed, never sent; it comes back with the
/// ones he misses again until none is left (the user, 2026-09-26).
final class ReviewRound extends LessonRound {
  const ReviewRound(this.evaluation);

  /// The first round's result, which the finish screen shows.
  final LessonEvaluation evaluation;

  @override
  bool operator ==(Object other) =>
      other is ReviewRound && identical(other.evaluation, evaluation);

  @override
  int get hashCode => Object.hash(ReviewRound, evaluation);
}

/// One question of the running lesson, with the student's attempt at it.
///
/// [question] and the evaluations compare by identity: they are the server's
/// objects, carried from state to state and never rebuilt.
@immutable
class LessonQuestionState {
  const LessonQuestionState({
    required this.question,
    this.shownAt,
    this.attempt,
  });

  final MultipleChoiceQuestion question;

  /// When it took the screen; null until it has.
  final DateTime? shownAt;
  final LessonAttempt? attempt;

  bool get isCorrect => attempt?.choice == question.correctAnswerIndex;

  @override
  bool operator ==(Object other) =>
      other is LessonQuestionState &&
      identical(other.question, question) &&
      other.shownAt == shownAt &&
      other.attempt == attempt;

  @override
  int get hashCode => Object.hash(question, shownAt, attempt);
}

/// The choice he entered on a question, and how long it was on screen first.
@immutable
class LessonAttempt {
  const LessonAttempt({required this.choice, required this.secondsSpent});

  final int choice;
  final int secondsSpent;

  @override
  bool operator ==(Object other) =>
      other is LessonAttempt &&
      other.choice == choice &&
      other.secondsSpent == secondsSpent;

  @override
  int get hashCode => Object.hash(choice, secondsSpent);
}
