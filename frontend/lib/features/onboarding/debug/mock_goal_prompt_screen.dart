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
];

/// Simulates fetching the 6 static multiple-choice questions with a brief delay.
Future<List<MockMultipleChoiceQuestion>> fetchMockObjectiveQuestions(
  BuildContext context,
  String prompt,
) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return mockQuestions;
}
