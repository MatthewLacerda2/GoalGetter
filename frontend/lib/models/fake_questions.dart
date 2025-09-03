//INFO: this is just a placeholder model. Once we get the client_sdk, this'll be deleted
import 'question_data.dart';

//fake questions
List<QuestionData> fakeAcousticGuitarQuestions = [
  QuestionData(
    question: 'What is the standard tuning for acoustic guitar?',
    choices: ['EADGBE', 'DADGAD', 'CGCFAD', 'EADGBE'],
    correctAnswer: 'EADGBE',
  ),
  QuestionData(
    question: 'Which part of the acoustic guitar amplifies the sound?',
    choices: ['The neck', 'The sound hole', 'The bridge', 'The tuning pegs'],
    correctAnswer: 'The sound hole',
  ),
  QuestionData(
    question: 'Which letter represents the uppermost note in the guitar?',
    choices: ['E', 'A', 'D', 'G'],
    correctAnswer: 'E',
  ),
  QuestionData(
    question: 'Which letter represents the lowest note in the guitar?',
    choices: ['E', 'A', 'D', 'G'],
    correctAnswer: 'D',
  ),
];