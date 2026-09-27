import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/home/presentation/controllers/home_controller.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/lesson_controller.dart';

import '../api_fake.dart';
import 'lesson_json.dart';

/// A lesson opened over [fake], kept alive and disposed with the test.
Future<ProviderContainer> openedOver(
  ApiFake fake, {
  String? goalId = 'g1',
}) async {
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: await fake.overrides(goalId: goalId),
  );
  addTearDown(container.dispose);
  container.listen(lessonControllerProvider, (_, __) {});
  // A failed start is read back from the provider's AsyncError.
  await container
      .read(lessonControllerProvider.future)
      .then<void>((_) {}, onError: (Object _) {});
  return container;
}

extension on ProviderContainer {
  LessonController get lesson => read(lessonControllerProvider.notifier);

  AsyncValue<LessonState> get async => read(lessonControllerProvider);

  LessonState? get state => async.value;

  LessonAnswering get answering => state! as LessonAnswering;

  /// Answers the current question with [choice] and moves on.
  Future<void> answer(int choice) async {
    lesson
      ..selectChoice(choice)
      ..submitAnswer();
    await lesson.nextQuestion();
  }
}

List<Map<String, dynamic>> sentAnswers(ApiFake fake) {
  final body = fake.requests.lastWhere((r) => r.$1 == answersKey).$2;
  final answers = (jsonDecode(body) as Map<String, dynamic>)['answers'];
  return (answers as List).cast<Map<String, dynamic>>();
}

void main() {
  test(
    'submits one first attempt per question, never the review round',
    () async {
      final fake = ApiFake({
        startKey: [(201, lessonJson(3))],
        answersKey: [(200, evaluationJson)],
      });
      final c = await openedOver(fake);

      await c.answer(0); // right
      await c.answer(3); // wrong (correct is 1)
      await c.answer(2); // right: the lesson is submitted here

      expect(
        sentAnswers(fake).map((a) => (a['question_id'], a['choice_index'])),
        [('q0', 0), ('q1', 3), ('q2', 2)],
      );
      final intro = c.state! as LessonReviewIntro;
      expect(intro.missed.map((q) => q.id), ['q1']);

      c.lesson.startReview();
      await c.answer(1);
      expect((c.state! as LessonFinished).evaluation.elo, 12);
      expect(fake.count(answersKey), 1);
    },
  );

  test('all right the first time finishes without a review', () async {
    final fake = ApiFake({
      startKey: [(201, lessonJson(2))],
      answersKey: [(200, evaluationJson)],
    });
    final c = await openedOver(fake);
    await c.answer(0);
    await c.answer(1);
    expect(c.state, isA<LessonFinished>());
  });

  test(
    'the review comes back with what he missed again, until none is left',
    () async {
      // The user, 2026-09-26: three wrong is three to correct; if two of
      // those come out right, the third comes back.
      final fake = ApiFake({
        startKey: [(201, lessonJson(3))],
        answersKey: [(200, evaluationJson)],
      });
      final c = await openedOver(fake);
      for (var i = 0; i < 3; i++) {
        await c.answer(3); // all wrong (question i's answer is i)
      }

      c.lesson.startReview();
      await c.answer(0); // right
      await c.answer(3); // wrong again
      await c.answer(2); // right

      expect(c.answering.round, isA<ReviewRound>());
      expect(c.answering.questions.map((q) => q.question.id), ['q1']);
      await c.answer(1); // right at last
      expect(c.state, isA<LessonFinished>());
      expect(fake.count(answersKey), 1);
    },
  );

  test('a question cannot be passed before it is answered', () async {
    // #86: the API refuses an incomplete lesson with a 400, so the controller
    // must not be able to build one. It used to let the lesson move past an
    // unanswered question.
    final fake = ApiFake({
      startKey: [(201, lessonJson(2))],
      answersKey: [(200, evaluationJson)],
    });
    final c = await openedOver(fake);
    await c.answer(0);
    await c.lesson.nextQuestion(); // nothing entered on question 2
    c.lesson.submitAnswer(); // nor tapped

    expect(fake.count(answersKey), 0);
    expect(c.answering.index, 1);
    expect(c.answering.isRevealed, isFalse);

    await c.answer(1);
    expect(sentAnswers(fake).map((a) => a['question_id']), ['q0', 'q1']);
  });

  test('the time on each question is read from the clock', () async {
    var now = DateTime(2026, 9, 26, 10);
    await withClock(Clock(() => now), () async {
      final fake = ApiFake({
        startKey: [(201, lessonJson(3))],
        answersKey: [(200, evaluationJson)],
      });
      final c = await openedOver(fake);
      now = now.add(const Duration(seconds: 7));
      await c.answer(0);
      now = now.add(const Duration(seconds: 1));
      await c.answer(1); // under the floor of 2 s
      now = now.add(const Duration(hours: 2));
      await c.answer(2); // over the ceiling of an hour

      expect(sentAnswers(fake).map((a) => a['seconds_spent']), [7, 2, 3600]);
    });
  });

  test('a 409 on start is "still being prepared", not a spinner', () async {
    final fake = ApiFake({
      startKey: [(409, '{"detail": "Lessons are still being prepared"}')],
    });
    final c = await openedOver(fake);
    expect(c.async, const AsyncData<LessonState>(LessonNotReady()));
  });

  test('no active goal on the device opens nothing', () async {
    final fake = ApiFake({});
    final c = await openedOver(fake, goalId: null);
    expect(c.state, const LessonNoActiveGoal());
    expect(fake.requests, isEmpty);
  });

  test(
    'a failed start is the error, and invalidating opens a new lesson',
    () async {
      final fake = ApiFake({
        startKey: [(500, '{"detail": "boom"}'), (201, lessonJson(1))],
      });
      final c = await openedOver(fake);
      expect((c.async.error as ApiException?)?.detail, 'boom');

      c.invalidate(lessonControllerProvider);
      await c.read(lessonControllerProvider.future);
      expect(c.answering.questions.single.question.id, 'q0');
    },
  );

  test('a failed submit keeps the answers, and the retry sends them', () async {
    final fake = ApiFake({
      startKey: [(201, lessonJson(2))],
      answersKey: [(500, '{"detail": "boom"}'), (200, evaluationJson)],
    });
    final c = await openedOver(fake);
    await c.answer(0);
    await c.answer(1);

    final round = c.answering.round as FirstRound;
    expect((round.submitFailure as ApiException?)?.detail, 'boom');
    expect(c.answering.isRevealed, isTrue);
    final firstTry = sentAnswers(fake);

    await c.lesson.retrySubmit();
    expect(sentAnswers(fake), firstTry);
    expect(c.state, isA<LessonFinished>());
  });

  test('a finished lesson refreshes Home', () async {
    final fake = ApiFake({
      startKey: [(201, lessonJson(1))],
      answersKey: [(200, evaluationJson)],
      'GET /home': [(404, '{"detail": "No active goal"}')],
    });
    final c = await openedOver(fake);
    c.listen(homeControllerProvider, (_, __) {});
    await c.read(homeControllerProvider.future);

    await c.answer(0);
    await c.read(homeControllerProvider.future);

    expect(fake.count('GET /home'), 2);
  });

  test('a lesson left mid-submit drops the answer quietly', () async {
    final fake = ApiFake({
      startKey: [(201, lessonJson(1))],
      answersKey: [(200, evaluationJson)],
    });
    final c = await openedOver(fake);
    c.lesson
      ..selectChoice(0)
      ..submitAnswer();
    final submitting = c.lesson.nextQuestion();
    c.dispose(); // the student left the lesson screen

    await expectLater(submitting, completes);
  });
}
