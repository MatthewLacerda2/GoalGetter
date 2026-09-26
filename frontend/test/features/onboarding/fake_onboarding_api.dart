import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/domain/study_plan.dart';

const question = ObjectiveQuestion(
  question: 'How much Italian do you know?',
  options: ['None', 'A few words', 'Basic chats', 'Fluent'],
);

const plan = StudyPlan(goalName: 'Travel Italian', description: 'Greetings.');

const draft = GoalDraft(
  prompt: 'Learn Italian well enough to travel',
  answers: [
    ObjectiveAnswer(question: 'Level?', answer: 'None', totalSeconds: 7),
  ],
  plan: plan,
);

const created = CreatedGoal(
  id: 'g1',
  name: 'Travel Italian',
  standardQuestions: [
    StandardQuestion(
      key: 'age',
      optionKeys: ['under18', '18to24', '25to39', '40plus'],
    ),
    StandardQuestion(
      key: 'purpose',
      optionKeys: ['school', 'work', 'project', 'curiosity'],
    ),
  ],
);

const geminiDown = ApiException(503, 'The model is overloaded');
const notAGoal = ApiException(400, 'This does not describe something to learn');
const rateLimited = ApiException(429, 'HTTP 429');

/// A backend that answers the fixtures above. A non-null error field makes
/// that call throw it; the last request of each call is recorded.
class FakeOnboardingApi implements OnboardingApi {
  Object? questionsError;
  Object? planError;
  Object? createError;
  String? lastPrompt;
  List<ObjectiveAnswer>? lastAnswers;
  GoalDraft? lastCreated;
  String? lastAnsweredGoalId;
  List<StandardAnswer>? lastStandardAnswers;

  @override
  Future<List<ObjectiveQuestion>> objectiveQuestions(String prompt) async {
    lastPrompt = prompt;
    if (questionsError != null) throw questionsError!;
    return const [question];
  }

  @override
  Future<StudyPlan> studyPlan(
    String prompt,
    List<ObjectiveAnswer> answers,
  ) async {
    lastAnswers = answers;
    if (planError != null) throw planError!;
    return plan;
  }

  @override
  Future<CreatedGoal> create(GoalDraft draft) async {
    lastCreated = draft;
    if (createError != null) throw createError!;
    return created;
  }

  @override
  Future<void> sendStandardAnswers(
    String goalId,
    List<StandardAnswer> answers,
  ) async {
    lastAnsweredGoalId = goalId;
    lastStandardAnswers = answers;
  }
}
