import 'package:goal_getter/features/onboarding/domain/study_plan.dart';

/// One clarifying question of `POST /goals/objective-questions`: exactly four
/// options, none of them "correct" (they profile the student).
class ObjectiveQuestion {
  final String question;
  final List<String> options;

  const ObjectiveQuestion({required this.question, required this.options});

  factory ObjectiveQuestion.fromJson(Map<String, dynamic> json) =>
      ObjectiveQuestion(
        question: json['question'] as String,
        options: (json['options'] as List).cast<String>(),
      );
}

/// The option the student picked for one question.
class ObjectiveAnswer {
  final String question;
  final String answer;

  const ObjectiveAnswer({required this.question, required this.answer});

  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};
}

/// Everything the student has said and approved so far. It outlives a detour
/// to the sign-in screen (see `PendingGoalDraft`), so `POST /goals` can be
/// sent with exactly what they saw.
class GoalDraft {
  final String prompt;
  final List<ObjectiveAnswer> answers;
  final StudyPlan plan;

  const GoalDraft({
    required this.prompt,
    required this.answers,
    required this.plan,
  });
}

/// One introduction screen shown after the goal is created. [icon] is a name
/// from the backend's fixed `IntroIcon` set (see `intro_icons.dart`).
class IntroScreenData {
  final String icon;
  final String title;
  final String text;

  const IntroScreenData({
    required this.icon,
    required this.title,
    required this.text,
  });

  factory IntroScreenData.fromJson(Map<String, dynamic> json) =>
      IntroScreenData(
        icon: json['icon'] as String,
        title: json['title'] as String,
        text: json['text'] as String,
      );
}

/// `POST /goals` 201: the new goal and its introduction screens.
class CreatedGoal {
  final String id;
  final String name;
  final List<IntroScreenData> introScreens;

  const CreatedGoal({
    required this.id,
    required this.name,
    required this.introScreens,
  });

  factory CreatedGoal.fromJson(Map<String, dynamic> json) => CreatedGoal(
    id: json['id'] as String,
    name: json['name'] as String,
    introScreens: (json['introduction_screen_data'] as List)
        .map((e) => IntroScreenData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
