import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

/// Generates a mock study plan response based on the user's prompt and answers.
Future<GoalStudyPlanResponse> generateMockStudyPlan(
  BuildContext context,
  String prompt,
  List<String> answers,
) async {
  // Simulate network/AI delay
  await Future.delayed(const Duration(milliseconds: 1200));

  return GoalStudyPlanResponse(
    goalName: "Goal: $prompt",
    goalDescription: "A comprehensive roadmap tailored to your objective: '$prompt'. Based on your answers, we have prioritized hands-on project work and structured resources for efficient learning.",
    firstObjectiveName: "Orientation and Foundation Building",
    firstObjectiveDescription: "Establish your local/development environment, understand the key core concepts, and build a simple foundation project to build momentum.",
    milestones: [
      "Milestone 1: Environment configuration and baseline setups",
      "Milestone 2: Fundamentals, core syntax, and structure exercises",
      "Milestone 3: Building your first functional prototype",
      "Milestone 4: Integrating persistent data, APIs, or advanced states",
      "Milestone 5: Testing, code refactoring, and project release",
    ],
  );
}
