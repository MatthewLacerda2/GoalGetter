import 'package:flutter/material.dart';
import '../../models/question_data.dart';
import '../../widgets/screens/objective/lesson/question.dart';
import '../intermediate/info_screen.dart';
import '../objective/finish_lesson_screen.dart';

class LessonScreen extends StatefulWidget {
  final List<QuestionData> questions;

  const LessonScreen({
    super.key,
    required this.questions,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int currentQuestionIndex = 0;
  List<QuestionData> questions = [];
  bool isShowingCorrection = false;

  @override
  void initState() {
    super.initState();
    questions = List.from(widget.questions);
  }

  void _handleQuestionAnswered(int selectedIndex) {
    final currentQuestion = questions[currentQuestionIndex];
    final isCorrect = currentQuestion.choices[selectedIndex] == currentQuestion.correctAnswer;
    
    setState(() {
      if (isCorrect) {
        currentQuestion.status = currentQuestion.status == QuestionStatus.notAnswered 
            ? QuestionStatus.correct 
            : QuestionStatus.correctAfterRetry;
      } else {
        currentQuestion.status = QuestionStatus.incorrect;
      }
    });
  }

  void _handleAnswerRevealed() {
    // Wait 2 seconds to show the answer feedback, then proceed
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _proceedToNext();
      }
    });
  }

  void _proceedToNext() {
    setState(() {
      currentQuestionIndex++;
    });
  }

  void _startCorrection() {
    setState(() {
      isShowingCorrection = true;
      currentQuestionIndex = 0;
    });
  }

  void _finishLesson() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const FinishLessonScreen(),
      ),
    );
  }

  bool _hasIncorrectQuestions() {
    return questions.any((q) => q.status == QuestionStatus.incorrect);
  }

  bool _allQuestionsCompleted() {
    return questions.every((q) => 
        q.status == QuestionStatus.correct || 
        q.status == QuestionStatus.correctAfterRetry);
  }

  List<QuestionData> _getIncorrectQuestions() {
    return questions.where((q) => q.status == QuestionStatus.incorrect).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Check if we should show correction screen
    if (isShowingCorrection && _getIncorrectQuestions().isEmpty) {
      _finishLesson();
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show correction info screen
    if (isShowingCorrection && currentQuestionIndex == 0) {
      return InfoScreen(
        icon: Icons.school,
        descriptionText: "Now let's correct your mistakes",
        buttonText: "Continue",
        onButtonPressed: _proceedToNext,
      );
    }

    // Show finish screen if all questions are completed
    if (!isShowingCorrection && _allQuestionsCompleted()) {
      _finishLesson();
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Show correction info screen after first pass
    if (!isShowingCorrection && currentQuestionIndex >= questions.length && _hasIncorrectQuestions()) {
      return InfoScreen(
        icon: Icons.school,
        descriptionText: "Now let's correct your mistakes",
        buttonText: "Continue",
        onButtonPressed: _startCorrection,
      );
    }

    // Get current question (either from main list or incorrect questions)
    QuestionData currentQuestion;
    if (isShowingCorrection) {
      final incorrectQuestions = _getIncorrectQuestions();
      currentQuestion = incorrectQuestions[currentQuestionIndex];
    } else {
      currentQuestion = questions[currentQuestionIndex];
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Progress indicator
              Row(
                children: [
                  Text(
                    'Question ${currentQuestionIndex + 1} of ${isShowingCorrection ? _getIncorrectQuestions().length : questions.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (isShowingCorrection)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Correction',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Question widget
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Question(
                    key: ValueKey('${currentQuestion.question}_${currentQuestionIndex}'),
                    questionData: currentQuestion,
                    onChoiceSelected: _handleQuestionAnswered,
                    onAnswerRevealed: _handleAnswerRevealed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}