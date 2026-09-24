import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_onboarding_api.dart';
import 'onboarding_harness.dart';

const _prompt = 'Learn Italian well enough to travel';

Future<void> submit(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField), _prompt);
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
}

String fieldText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  testWidgets('a 400 shows the reasoning and stays on the prompt', (
    tester,
  ) async {
    await pumpFlow(tester, FakeOnboardingApi()..questionsError = notAGoal);
    await submit(tester);
    expect(find.text(notAGoal.detail), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(fieldText(tester), _prompt);
    expect(find.text(question.question), findsNothing);
  });

  testWidgets('a failed call keeps the prompt and retries it', (tester) async {
    final api = FakeOnboardingApi()..questionsError = geminiDown;
    await pumpFlow(tester, api);
    await submit(tester);
    expect(find.text(geminiDown.detail), findsOneWidget);
    expect(fieldText(tester), _prompt);

    api.questionsError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text(question.question), findsOneWidget);
    expect(api.lastPrompt, _prompt);
  });

  testWidgets('the rate limit reads as a sentence, not a status', (
    tester,
  ) async {
    await pumpFlow(tester, FakeOnboardingApi()..questionsError = rateLimited);
    await submit(tester);
    expect(find.textContaining('Too many tries'), findsOneWidget);
  });
}
