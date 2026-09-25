import 'package:flutter/material.dart';

import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/stat_data.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/domain/study_plan.dart';
import 'package:goal_getter/app/theme/app_theme.dart';

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
        questions: [
          ObjectiveQuestion(
            question: 'What is your current experience with Italian?',
            options: [
              'None at all',
              'I know a few words',
              'I can hold a simple conversation',
              'I studied it before and forgot',
            ],
          ),
          ObjectiveQuestion(
            question: 'How much time can you commit to learning daily?',
            options: [
              'Less than 15 minutes',
              '15 to 30 minutes',
              '30 to 60 minutes',
              'More than 60 minutes',
            ],
          ),
        ],
      );

  static GoalDraft get goalDraft => GoalDraft(
        prompt: goalPrompt,
        answers: const [
          ObjectiveAnswer(
            question: 'What is your current experience with Italian?',
            answer: 'I know a few words',
          ),
        ],
        plan: studyPlan,
      );

  /// The standard onboarding questions as `POST /goals` answers with them
  /// (#132): keys, in the order the backend's
  /// `services/onboarding/standard_questions.py` lists them. The screen draws
  /// the ARB sentences, so this fixture carries no prose of its own.
  static StandardQuestionsArgs get standardQuestions =>
      const StandardQuestionsArgs(
        goalId: 'goal_italian',
        questions: [
          StandardQuestion(
            key: 'age',
            optionKeys: ['under18', '18to24', '25to39', '40plus'],
          ),
          StandardQuestion(
            key: 'purpose',
            optionKeys: ['school', 'work', 'project', 'curiosity'],
          ),
          StandardQuestion(
            key: 'level',
            optionKeys: ['nothing', 'little', 'enough', 'deep'],
          ),
          StandardQuestion(
            key: 'time',
            optionKeys: ['minutes', 'quarter', 'half', 'hour'],
          ),
        ],
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
          color: AppTheme.lost,
        ),
        accuracy: StatData(
          title: 'Accuracy',
          icon: Icons.check_circle_outline,
          text: '87%',
          color: AppTheme.success,
        ),
        elo: StatData(
          title: 'Elo',
          icon: Icons.trending_up,
          text: '+24',
          color: AppTheme.streak,
        ),
      );
}
