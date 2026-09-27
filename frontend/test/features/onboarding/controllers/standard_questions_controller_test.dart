import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/standard_questions_controller.dart';

import '../fake_onboarding_api.dart';
import 'onboarding_container.dart';

void main() {
  final provider = standardQuestionsControllerProvider(
    created.id,
    created.standardQuestions,
  );

  test('the last answer sends them all, with their seconds, and ends', () {
    var now = DateTime(2026, 9, 27);
    void wait(int seconds) => now = now.add(Duration(seconds: seconds));

    return withClock(Clock(() => now), () async {
      final api = FakeOnboardingApi();
      final (c, _) = await onboardingContainer(api);
      c.keep(provider);
      final controller = c.read(provider.notifier);

      wait(4);
      controller.pick('18to24');
      wait(1); // the pause that shows his pick is on no question
      controller.advance();
      expect(c.read(provider).index, 1);
      expect(c.read(provider).selected('age'), '18to24');
      wait(9);
      controller
        ..pick('work')
        ..advance();
      await pumpEventQueue();

      expect(c.read(provider).done, isTrue);
      expect(api.lastAnsweredGoalId, created.id);
      expect(
        api.lastStandardAnswers!.map((a) => (a.optionKey, a.totalSeconds)),
        [('18to24', 4), ('work', 9)],
      );
      expect(controller.pick('school'), isFalse, reason: 'he is done');
    });
  });

  test('skipping before any answer ends and sends nothing', () async {
    final api = FakeOnboardingApi();
    final (c, _) = await onboardingContainer(api);
    c.keep(provider);

    c.read(provider.notifier).finish();
    await pumpEventQueue();

    expect(c.read(provider).done, isTrue);
    expect(api.lastStandardAnswers, isNull);
  });
}
