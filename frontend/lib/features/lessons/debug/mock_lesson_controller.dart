import 'package:goal_getter/features/lessons/domain/lesson_models.dart';

/// Mock data source for the lesson flow, consumed by `lesson_controller.dart`.
///
/// Stands in for the (not-yet-built) backend lesson endpoints so the
/// Start lesson → answer → review → finish chain runs fully offline.

/// Simulates fetching a fresh multiple-choice activity for the active goal.
Future<List<MultipleChoiceQuestion>> getMockLessonQuestions() async {
  await Future.delayed(const Duration(milliseconds: 500));

  return const [
    MultipleChoiceQuestion(
      id: 'q1',
      question: 'How do you say "hello" in Italian?',
      choices: ['Ciao', 'Hola', 'Bonjour', 'Hallo'],
      correctAnswerIndex: 0,
    ),
    MultipleChoiceQuestion(
      id: 'q2',
      question: 'What is the Italian word for "thank you"?',
      choices: ['Prego', 'Grazie', 'Scusa', 'Per favore'],
      correctAnswerIndex: 1,
    ),
    MultipleChoiceQuestion(
      id: 'q3',
      question: 'Which word means "goodbye" in Italian?',
      choices: ['Buongiorno', 'Salve', 'Arrivederci', 'Benvenuto'],
      correctAnswerIndex: 2,
    ),
    MultipleChoiceQuestion(
      id: 'q4',
      question: '"Acqua" translates to which English word?',
      choices: ['Bread', 'Wine', 'Milk', 'Water'],
      correctAnswerIndex: 3,
    ),
    MultipleChoiceQuestion(
      id: 'q5',
      question: 'What does "uno, due, tre" mean?',
      choices: ['One, two, three', 'Red, green, blue', 'Yes, no, maybe', 'Big, small, tall'],
      correctAnswerIndex: 0,
    ),
  ];
}

/// Mock elo awarded for a lesson, based on accuracy (0..100).
///
/// Rewards high accuracy and slightly penalizes poor performance, so the
/// finish screen and Home chart show plausible signed values.
int mockEloForAccuracy(double accuracy) {
  return ((accuracy - 60) / 2).round();
}
