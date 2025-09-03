//INFO: this is just a placeholder model. Once we get the client_sdk, this'll be deleted

enum QuestionStatus{
  correct,
  incorrect,
  notAnswered,
  correctAfterRetry,
}


class QuestionData {
  final String question;
  final List<String> choices;
  final String correctAnswer;
  QuestionStatus status;

  QuestionData({
    required this.question,
    required this.choices,
    required this.correctAnswer,
  }) : status = QuestionStatus.notAnswered;
}