/// Frontend domain models for the lesson flow.
///
/// These intentionally replace the generated `client_sdk` types
/// (`MultipleChoiceQuestionResponse`, `MultipleChoiceActivityEvaluationResponse`)
/// because the backend for this version of the app does not exist yet. The
/// lesson runs entirely on mock data (see `debug/mock_lesson_controller.dart`).
library;

/// A single multiple-choice question shown during a lesson.
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
}

/// The result computed when a lesson is finished.
///
/// `elo` replaces the old `xp` concept (chess-like rating).
class LessonEvaluation {
  final int totalSecondsSpent;
  final double studentAccuracy; // 0..100
  final int elo;

  const LessonEvaluation({
    required this.totalSecondsSpent,
    required this.studentAccuracy,
    required this.elo,
  });
}
