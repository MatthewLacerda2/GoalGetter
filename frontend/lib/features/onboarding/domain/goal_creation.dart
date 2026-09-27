import 'package:goal_getter/features/onboarding/domain/study_plan.dart';

/// One clarifying question of `POST /goals/objective-questions`: exactly four
/// options, none of them "correct" (they profile the student), and the model
/// that wrote it.
class ObjectiveQuestion {
  final String question;
  final List<String> options;
  final String aiModel;

  const ObjectiveQuestion({
    required this.question,
    required this.options,
    required this.aiModel,
  });

  factory ObjectiveQuestion.fromJson(Map<String, dynamic> json) =>
      ObjectiveQuestion(
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        aiModel: json['ai_model'] as String,
      );
}

/// The option the student picked for one question, and the whole seconds he
/// spent on it (see `QuestionTimer`). No duration is sent as none: the
/// backend stores the answer either way.
///
/// [aiModel] is its question's, sent back so `POST /goals` records who wrote
/// the question: that request cannot know, the questions came from another
/// one. Without it the row says `"unknown"`.
class ObjectiveAnswer {
  final String question;
  final String answer;
  final int? totalSeconds;
  final String? aiModel;

  const ObjectiveAnswer({
    required this.question,
    required this.answer,
    this.totalSeconds,
    this.aiModel,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'answer': answer,
    if (totalSeconds != null) 'total_seconds': totalSeconds,
    if (aiModel != null) 'ai_model': aiModel,
  };
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

/// One standard onboarding question, as `POST /goals` hands it over: keys, not
/// sentences.
///
/// The four questions are written by us and live in the backend's
/// `services/onboarding/standard_questions.py`; what the student reads is the
/// ARB entry each key maps to (see `standard_question_text.dart`), in all five
/// locales. The key is what travels in both directions, so the English the
/// database keeps for the prompts never depends on the locale he answered in.
class StandardQuestion {
  final String key;
  final List<String> optionKeys;

  const StandardQuestion({required this.key, required this.optionKeys});

  factory StandardQuestion.fromJson(Map<String, dynamic> json) =>
      StandardQuestion(
        key: json['key'] as String,
        optionKeys: List<String>.from(json['options'] as List),
      );
}

/// One answer to a standard question: the question's key, the key of the
/// option picked, and the whole seconds he spent on it.
class StandardAnswer {
  final String questionKey;
  final String optionKey;
  final int? totalSeconds;

  const StandardAnswer({
    required this.questionKey,
    required this.optionKey,
    this.totalSeconds,
  });

  Map<String, dynamic> toJson() => {
    'question_key': questionKey,
    'option_key': optionKey,
    if (totalSeconds != null) 'total_seconds': totalSeconds,
  };
}

/// `POST /goals` 201: the new goal and the questions to ask while its first
/// batch of lesson questions generates.
class CreatedGoal {
  final String id;
  final String name;
  final List<StandardQuestion> standardQuestions;

  const CreatedGoal({
    required this.id,
    required this.name,
    required this.standardQuestions,
  });

  factory CreatedGoal.fromJson(Map<String, dynamic> json) => CreatedGoal(
    id: json['id'] as String,
    name: json['name'] as String,
    standardQuestions: (json['standard_questions'] as List)
        .map((e) => StandardQuestion.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
