//INFO: this is just a placeholder model. Once we get the client_sdk, this'll be deleted

enum QuestionStatus{
  correct,
  incorrect,
  notAnswered,
}


class QuestionData {
  final String question;
  final List<String> choices;
  final int correctAnswerIndex;
  QuestionStatus status;

  QuestionData({
    required this.question,
    required this.choices,
    required this.correctAnswerIndex,
  }) : status = QuestionStatus.notAnswered;
}