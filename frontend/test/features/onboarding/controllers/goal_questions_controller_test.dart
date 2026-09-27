import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/goal_questions_controller.dart';

import '../fake_onboarding_api.dart';
import 'onboarding_container.dart';

const _second = ObjectiveQuestion(
  question: 'What for?',
  options: ['Travel', 'Work', 'Family', 'Fun'],
);
const _questions = [question, _second];
const _one = [question];

void main() {
  // #174: from the question taking the screen to the tap that answers it. The
  // slide between two questions is on neither.
  test('each answer carries the seconds its question was on screen', () {
    var now = DateTime(2026, 9, 27);
    void wait(int seconds) => now = now.add(Duration(seconds: seconds));

    return withClock(Clock(() => now), () async {
      final api = FakeOnboardingApi();
      final (c, _) = await onboardingContainer(api);
      final provider = goalQuestionsControllerProvider('Italian', _questions);
      c.keep(provider);
      final controller = c.read(provider.notifier);

      wait(5);
      controller
        ..select('A few words')
        ..leave();
      wait(3);
      controller.move(1);
      wait(7);
      controller.select('Travel');
      await controller.requestPlan();

      expect(api.lastAnswers!.map((a) => a.answer), ['A few words', 'Travel']);
      expect(api.lastAnswers!.map((a) => a.totalSeconds), [5, 7]);
      final ready = c.read(provider).plan as PlanReady;
      expect(ready.draft.prompt, 'Italian');
      expect(ready.draft.plan, plan);
    });
  });

  test('a failed plan keeps every answer, and the retry sends them', () async {
    final api = FakeOnboardingApi()..planError = geminiDown;
    final (c, _) = await onboardingContainer(api);
    final provider = goalQuestionsControllerProvider('Italian', _one);
    c.keep(provider);
    final controller = c.read(provider.notifier)..select('Fluent');

    final sent = controller.requestPlan();
    expect(c.read(provider).plan, isA<PlanLoading>());
    expect(controller.select('None'), isFalse, reason: 'already sent');
    await sent;
    expect((c.read(provider).plan as PlanFailed).error, geminiDown);
    expect(c.read(provider).answers, ['Fluent']);

    api.planError = null;
    await controller.requestPlan();
    expect(c.read(provider).plan, isA<PlanReady>());
    expect(api.lastAnswers!.single.answer, 'Fluent');
  });

  test('back from the plan, the last question is on screen again', () async {
    final (c, _) = await onboardingContainer(FakeOnboardingApi());
    final provider = goalQuestionsControllerProvider('Italian', _one);
    c.keep(provider);
    final controller = c.read(provider.notifier)..select('None');
    await controller.requestPlan();

    controller.resume();
    expect(c.read(provider).plan, isA<PlanNotAsked>());
    expect(c.read(provider).isLast, isTrue);
  });
}
