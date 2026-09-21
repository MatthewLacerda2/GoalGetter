//INFO: placeholder model. To be replaced by the hand-written API layer (core/api).

enum LessonQuestionStatus{
  correct,
  incorrect,
  notAnswered,
  correctAfterRetry,
}


class LessonQuestionData {
  final String question;
  final List<String> choices;
  final String correctAnswer;
  LessonQuestionStatus status;

  LessonQuestionData({
    required this.question,
    required this.choices,
    required this.correctAnswer,
  }) : status = LessonQuestionStatus.notAnswered;
}