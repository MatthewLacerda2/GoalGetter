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

/// An opened lesson: its questions, in order.
///
/// There is no lesson id: serving a lesson writes nothing on the backend, and
/// the id that groups the answers is minted there when they arrive.
class LessonSession {
  final List<MultipleChoiceQuestion> questions;

  const LessonSession({required this.questions});

  factory LessonSession.fromJson(Map<String, dynamic> json) => LessonSession(
        questions: (json['questions'] as List)
            .cast<Map<String, dynamic>>()
            .map(MultipleChoiceQuestion.fromJson)
            .toList(growable: false),
      );
}

/// One answer, in the order the student gave it - which is the order the
/// backend records as its position inside the lesson.
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

/// The result of a finished lesson: `elo` is the signed rating change the
/// server applied.
class LessonEvaluation {
  final int totalSecondsSpent;
  final double studentAccuracy; // 0..100
  final int elo;

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
