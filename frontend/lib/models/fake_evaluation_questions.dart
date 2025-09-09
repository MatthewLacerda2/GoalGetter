import 'evaluation_answers.dart';

List<EvaluationAnswers> fakeEvaluationAnswers = [
  EvaluationAnswers(
    question: 'Does the pitch go lower or higher as you move up the guitar? Why?',
    studentAnswer: 'Higher because there the vibrations in the strings have to travel shorter distances',
    llmEvaluation: 'Correct',
    isCorrect: true,
  ),
  EvaluationAnswers(
    question: 'What is the standard tuning for acoustic guitar?',
    studentAnswer: 'EADGBE',
    llmEvaluation: 'Correct',
    isCorrect: true,
  ),
  EvaluationAnswers(
    question: 'What happens if i move up by one fret?',
    studentAnswer: 'I play the next note',
    llmEvaluation: 'Maybe. I might just play the sharp version of the note',
    isCorrect: false,
  ),
];