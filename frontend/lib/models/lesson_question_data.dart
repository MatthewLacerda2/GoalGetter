//INFO: this is just a placeholder model. Once we get the client_sdk, this'll be deleted

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