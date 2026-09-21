/// Frontend domain models for the lesson flow, read from
/// `backend/schemas/lesson.py` (POST /goals/{goal_id}/lessons and its
/// /answers).
library;

/// How the student did on a question, as the lesson screen tracks it.
enum LessonQuestionStatus {
  correct,
  incorrect,
  notAnswered,
  correctAfterRetry,
}

/// A single multiple-choice question shown during a lesson.
///
/// `correctAnswerIndex` comes from the server on purpose: the app grades inline
/// for feedback, and the server re-grades on submit.
class MultipleChoiceQuestion {
  final String id;
  final String question;
  final List<String> choices;
  final int correctAnswerIndex;

  const MultipleChoiceQuestion({
    required this.id,
    required this.question,
    required this.choices,
    required this.correctAnswerIndex,
  });

  factory MultipleChoiceQuestion.fromJson(Map<String, dynamic> json) =>
      MultipleChoiceQuestion(
        id: json['id'] as String,
        question: json['question'] as String,
        choices: (json['choices'] as List).cast<String>(),
        correctAnswerIndex: json['correct_answer_index'] as int,
      );
}

/// An opened lesson: its id (needed to submit) and its questions, in order.
class LessonSession {
  final String lessonId;
  final List<MultipleChoiceQuestion> questions;

  const LessonSession({required this.lessonId, required this.questions});

  factory LessonSession.fromJson(Map<String, dynamic> json) => LessonSession(
        lessonId: json['lesson_id'] as String,
        questions: (json['questions'] as List)
            .cast<Map<String, dynamic>>()
            .map(MultipleChoiceQuestion.fromJson)
            .toList(growable: false),
      );
}

/// The student's first attempt at one question.
class LessonAnswer {
  final String questionId;
  final int choiceIndex;
  final int secondsSpent;

  const LessonAnswer({
    required this.questionId,
    required this.choiceIndex,
    required this.secondsSpent,
  });

  Map<String, Object> toJson() => {
        'question_id': questionId,
        'choice_index': choiceIndex,
        'seconds_spent': secondsSpent,
      };
}

/// The result of a finished lesson.
///
/// `elo` is the signed rating change the server applied. It is null only when
/// the server's evaluation was lost: a submit whose answer never arrived, then
/// retried into 409 "already answered". The time and accuracy are then the
/// app's own count of the same first attempts.
class LessonEvaluation {
  final int totalSecondsSpent;
  final double studentAccuracy; // 0..100
  final int? elo;

  const LessonEvaluation({
    required this.totalSecondsSpent,
    required this.studentAccuracy,
    required this.elo,
  });

  factory LessonEvaluation.fromJson(Map<String, dynamic> json) =>
      LessonEvaluation(
        totalSecondsSpent: json['total_seconds_spent'] as int,
        studentAccuracy: (json['student_accuracy'] as num).toDouble(),
        elo: json['elo'] as int,
      );
}
