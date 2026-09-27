import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/goal_prompt_controller.dart';

import '../fake_onboarding_api.dart';
import 'onboarding_container.dart';

void main() {
  test('a prompt too short to write questions about sends nothing', () async {
    final api = FakeOnboardingApi();
    final (c, _) = await onboardingContainer(api);
    c.keep(goalPromptControllerProvider);

    await c.read(goalPromptControllerProvider.notifier).ask('  Italian  ');

    expect(c.read(goalPromptControllerProvider), isA<PromptTooShort>());
    expect(api.lastPrompt, isNull);
  });

  test('a prompt is trimmed, sent, and its questions come back', () async {
    final api = FakeOnboardingApi();
    final (c, _) = await onboardingContainer(api);
    c.keep(goalPromptControllerProvider);

    final sent = c
        .read(goalPromptControllerProvider.notifier)
        .ask('  Learn Italian to travel  ');
    expect(c.read(goalPromptControllerProvider), isA<PromptAsking>());
    await sent;

    final state = c.read(goalPromptControllerProvider) as PromptAccepted;
    expect(api.lastPrompt, 'Learn Italian to travel');
    expect(state.prompt, 'Learn Italian to travel');
    expect(state.questions, [question]);
  });

  test('a 400 is a rejection; any other failure is worth a retry', () async {
    final api = FakeOnboardingApi()..questionsError = notAGoal;
    final (c, _) = await onboardingContainer(api);
    c.keep(goalPromptControllerProvider);
    final controller = c.read(goalPromptControllerProvider.notifier);

    await controller.ask('Learn Italian to travel');
    var failed = c.read(goalPromptControllerProvider) as PromptFailed;
    expect(failed.error, notAGoal);
    expect(failed.rejected, isTrue);

    api.questionsError = geminiDown;
    await controller.ask('Learn Italian to travel');
    failed = c.read(goalPromptControllerProvider) as PromptFailed;
    expect(failed.rejected, isFalse);
  });
}
