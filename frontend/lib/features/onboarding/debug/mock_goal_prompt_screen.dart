import 'package:flutter/material.dart';

class MockMultipleChoiceQuestion {
  final String questionText;
  final List<String> options;

  const MockMultipleChoiceQuestion({
    required this.questionText,
    required this.options,
  });
}

const List<MockMultipleChoiceQuestion> mockQuestions = [
  MockMultipleChoiceQuestion(
    questionText: "What is your primary learning goal?",
    options: [
      "Career advancement / job requirement",
      "Personal interest / curiosity",
      "School or academic project",
      "Building a startup, side project, or product"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "What is your current experience level in this subject?",
    options: [
      "Absolute beginner (no prior knowledge)",
      "Novice (understand basic terms/concepts)",
      "Intermediate (built some small projects)",
      "Advanced (looking to master advanced topics)"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "How much time can you commit to learning daily?",
    options: [
      "Less than 15 minutes",
      "15 to 30 minutes",
      "30 to 60 minutes",
      "More than 60 minutes"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "What is your preferred learning style?",
    options: [
      "Hands-on coding, building, or practicing",
      "Reading articles, books, or documentation",
      "Watching video lectures or tutorials",
      "Solving interactive quizzes and challenges"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "What type of resources do you want to prioritize?",
    options: [
      "Only free online articles and videos",
      "A mix of free and paid online courses",
      "Official reference docs and textbooks",
      "Community forums and mentorship sessions"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "How do you want to track your progress?",
    options: [
      "Daily reminders and streak tracking",
      "Weekly self-assessments or quizzes",
      "Completing specific projects and milestones",
      "Self-paced without active tracking"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "What is your target timeline for this goal?",
    options: [
      "Less than 2 weeks",
      "2 to 4 weeks",
      "1 to 3 months",
      "More than 3 months"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "Which environment do you prefer for learning?",
    options: [
      "Local setup on my computer",
      "Cloud-based sandboxes or online editors",
      "Mobile-friendly reading / apps on the go",
      "Pen and paper planning first, then digital"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "What is your main motivation to stay consistent?",
    options: [
      "Gamification (points, badges, streaks)",
      "Public accountability (sharing progress)",
      "Peer accountability (study groups)",
      "Intrinsic focus / self-discipline"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "How deep do you want to go into the theoretical aspects?",
    options: [
      "Practical only (just show me how to build/do it)",
      "Balanced (application with essential core concepts)",
      "Deep dive (patterns, architecture, best practices)",
      "Academic (comprehensive theory and math/history)"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "What kind of project do you want to build by the end?",
    options: [
      "A simple clone of a popular service",
      "A fully custom portfolio project",
      "A utility tool to automate my daily work",
      "No specific project, just coding exercises"
    ],
  ),
  MockMultipleChoiceQuestion(
    questionText: "What has stopped you from achieving this goal in the past?",
    options: [
      "Lack of a structured roadmap or direction",
      "Time constraints / busy schedule",
      "Losing motivation or interest quickly",
      "Hitting complex issues and getting stuck"
    ],
  ),
];

/// Simulates fetching the 12 static multiple-choice questions with a brief delay.
Future<List<MockMultipleChoiceQuestion>> fetchMockObjectiveQuestions(
  BuildContext context,
  String prompt,
) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return mockQuestions;
}
