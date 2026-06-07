import 'package:flutter/material.dart';

import 'package:goal_getter/features/onboarding/domain/study_plan.dart';

/// Generates a mock study plan based on the user's prompt and answers.
///
/// The description is intentionally short and markdown-formatted so it fits the
/// screen and reads well in the app's type scale. In production this comes from
/// the AI; here it's a static blurb tailored to the prompt.
Future<StudyPlan> generateMockStudyPlan(
  BuildContext context,
  String prompt,
  List<String> answers,
) async {
  // Simulate network/AI delay.
  await Future.delayed(const Duration(milliseconds: 1200));

  final goalName = prompt.trim();

  return StudyPlan(
    goalName: goalName,
    description: 'To reach this goal, here is what we will work on:\n\n'
        '- Build a steady **daily practice** habit with short, focused lessons\n'
        '- Strengthen your **core fundamentals** so the basics feel effortless\n'
        '- Grow confidence with **real, practical exercises** you can use\n\n'
        'Each lesson adapts to you, and your **Elo** tracks your progress.',
  );
}
