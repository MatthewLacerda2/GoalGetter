import 'package:flutter/material.dart';

import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/stat_data.dart';
import 'package:goal_getter/features/onboarding/debug/mock_goal_prompt_screen.dart';
import 'package:goal_getter/features/onboarding/domain/study_plan.dart';

/// Fixtures for the dev menu (see dev_menu_screen.dart).
///
/// Several routes take rich objects through go_router's `extra` and would throw
/// a null cast if opened straight from a URL. The dev menu passes these instead,
/// so every screen is reachable without walking the whole flow first.
class DevFixtures {
  DevFixtures._();

  static const goalPrompt = 'Learn Italian well enough to travel';

  static GoalQuestionsArgs get goalQuestions => const GoalQuestionsArgs(
        prompt: goalPrompt,
        questions: mockQuestions,
      );

  static StudyPlan get studyPlan => const StudyPlan(
        goalName: 'Learn Italian',
        description:
            "You'll start with **greetings and introductions**, then move on to "
            "**ordering food** and **asking for directions**.\n\n"
            "Each lesson is short — about 5 minutes — and builds on the last one. "
            "By week three you'll hold a simple conversation about daily life.",
      );

  static Goal get goalDetail => Goal(
        id: 'goal_italian',
        name: 'Learn Italian',
        description:
            'Reach conversational fluency in Italian — hold a 10-minute chat '
            'about daily life, food, and travel without switching to English.',
        createdAt: DateTime(2026, 5, 31),
        updatedAt: DateTime(2026, 6, 6),
        currentElo: 920,
        isActive: true,
      );

  static FinishLessonArgs get finishLesson => FinishLessonArgs(
        title: 'Greetings & Introductions',
        icon: Icons.emoji_events,
        timeSpent: StatData(
          title: 'Time',
          icon: Icons.timer_outlined,
          text: '4:32',
          color: const Color(0xFF2563EB),
        ),
        accuracy: StatData(
          title: 'Accuracy',
          icon: Icons.check_circle_outline,
          text: '87%',
          color: const Color(0xFF16A34A),
        ),
        elo: StatData(
          title: 'Elo',
          icon: Icons.trending_up,
          text: '+24',
          color: const Color(0xFFF1820A),
        ),
      );
}
