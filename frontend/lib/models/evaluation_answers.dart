class EvaluationAnswers {
  final String question;
  final String studentAnswer;
  final String llmEvaluation;
  final bool isCorrect;

  EvaluationAnswers({
    required this.question,
    required this.studentAnswer,
    required this.llmEvaluation,
    required this.isCorrect,
  });
}