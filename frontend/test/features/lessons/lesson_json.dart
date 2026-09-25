/// A POST /goals/g1/lessons body with [n] questions; question i's correct
/// answer is choice i % 4.
String lessonJson(int n) {
  final questions = [
    for (var i = 0; i < n; i++)
      '{"id": "q$i", "question": "Question $i?",'
          ' "choices": ["a", "b", "c", "d"], "correct_answer_index": ${i % 4}}',
  ];
  return '{"questions": [${questions.join(',')}]}';
}

const evaluationJson =
    '{"total_seconds_spent": 6, "student_accuracy": 66.7, "elo": 12}';

const startKey = 'POST /goals/g1/lessons';
const answersKey = 'POST /goals/g1/lessons/answers';
