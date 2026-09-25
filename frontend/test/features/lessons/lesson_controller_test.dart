import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/features/home/presentation/controllers/home_controller.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/lesson_controller.dart';

import '../api_fake.dart';
import 'lesson_json.dart';

/// A running lesson controller over [fake]; disposed with the test.
Future<LessonController> controllerOver(ApiFake fake) async {
  final container = ProviderContainer(overrides: await fake.overrides());
  addTearDown(container.dispose);
  container.listen(lessonControllerProvider, (_, __) {});
  return container.read(lessonControllerProvider.notifier);
}

/// Answers the current question with [choice] and moves on.
Future<void> answer(LessonController c, int choice) async {
  c.selectChoice(choice);
  c.submitAnswer();
  await c.nextQuestion();
}

List<dynamic> sentAnswers(ApiFake fake) {
  final body = fake.requests.lastWhere((r) => r.$1 == answersKey).$2;
  return (jsonDecode(body) as Map<String, dynamic>)['answers'] as List;
}

void main() {
  test('submits one first attempt per question, never the review round',
      () async {
    final fake = ApiFake({
      startKey: [(201, lessonJson(3))],
      answersKey: [(200, evaluationJson)],
    });
    final c = await controllerOver(fake);
    await c.start();

    await answer(c, 0); // right
    await answer(c, 3); // wrong (correct is 1)
    await answer(c, 2); // right: the lesson is submitted here

    expect(sentAnswers(fake).map((a) => (a['question_id'], a['choice_index'])),
        [('q0', 0), ('q1', 3), ('q2', 2)]);
    expect(c.state.evaluationResponse?.elo, 12);

    c.startReviewMode([c.state.questions[1]]);
    await answer(c, 1);
    expect(c.state.isCompleted, isTrue);
    expect(fake.count(answersKey), 1);
  });

  test('a gap in the answers is returned to, never submitted', () async {
    // #86: the API refuses an incomplete lesson with a 400, so the controller
    // must not be able to build one. It used to drop the unanswered question
    // from the payload and send the rest.
    final fake = ApiFake({
      startKey: [(201, lessonJson(2))],
      answersKey: [(200, evaluationJson)],
    });
    final c = await controllerOver(fake);
    await c.start();
    await answer(c, 0);
    await c.nextQuestion(); // the end of the lesson, question 2 untouched

    expect(fake.count(answersKey), 0);
    expect(c.state.currentQuestionIndex, 1);
    expect(c.state.isAnswerRevealed, isFalse);
    expect(c.state.isCompleted, isFalse);

    await answer(c, 1);
    expect(sentAnswers(fake).map((a) => a['question_id']), ['q0', 'q1']);
  });

  test('a 409 on start is "still being prepared", not a spinner', () async {
    final fake = ApiFake({
      startKey: [(409, '{"detail": "Lessons are still being prepared"}')],
    });
    final c = await controllerOver(fake);
    await c.start();

    expect(c.state.isLoading, isFalse);
    expect(c.state.startFailure?.kind, LessonStartFailureKind.notReady);
  });

  test('a failed submit keeps the answers, and the retry sends them', () async {
    final fake = ApiFake({
      startKey: [(201, lessonJson(2))],
      answersKey: [(500, '{"detail": "boom"}'), (200, evaluationJson)],
    });
    final c = await controllerOver(fake);
    await c.start();
    await answer(c, 0);
    await answer(c, 1);

    expect((c.state.submitFailure?.cause as ApiException?)?.detail, 'boom');
    expect(c.state.isCompleted, isFalse);
    final firstTry = sentAnswers(fake);

    await c.retrySubmit();
    expect(sentAnswers(fake), firstTry);
    expect(c.state.isCompleted, isTrue);
  });

  test('a finished lesson refreshes Home', () async {
    final fake = ApiFake({
      startKey: [(201, lessonJson(1))],
      answersKey: [(200, evaluationJson)],
      'GET /home': [(404, '{"detail": "No active goal"}')],
    });
    final container = ProviderContainer(overrides: await fake.overrides());
    addTearDown(container.dispose);
    container.listen(homeControllerProvider, (_, __) {});
    container.listen(lessonControllerProvider, (_, __) {});
    await container.read(homeControllerProvider.future);

    final c = container.read(lessonControllerProvider.notifier);
    await c.start();
    await answer(c, 0);
    await container.read(homeControllerProvider.future);

    expect(fake.count('GET /home'), 2);
  });
}
