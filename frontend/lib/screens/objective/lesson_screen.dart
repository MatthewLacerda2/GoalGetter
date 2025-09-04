import 'package:flutter/material.dart';
import '../../models/question_data.dart';
import '../intermediate/info_screen.dart';
import 'finish_lesson_screen.dart';

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
  int? selectedChoiceIndex;
  bool isAnswerRevealed = false;
  List<QuestionData> questionsToReview = [];
  bool isReviewMode = false;

  @override
  void initState() {
    super.initState();
    questionsToReview = List.from(widget.questions);
  }

  void selectChoice(int index) {
    if (!isAnswerRevealed) {
      setState(() {
        selectedChoiceIndex = index;
      });
    }
  }

  void submitAnswer() {
    if (selectedChoiceIndex == null) return;

    setState(() {
      isAnswerRevealed = true;
      final currentQuestion = questionsToReview[currentQuestionIndex];
      final isCorrect = currentQuestion.choices[selectedChoiceIndex!] == currentQuestion.correctAnswer;
      
      if (isCorrect) {
        currentQuestion.status = QuestionStatus.correct;
      } else {
        currentQuestion.status = QuestionStatus.incorrect;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < questionsToReview.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedChoiceIndex = null;
        isAnswerRevealed = false;
      });
    } else {
      // Check if there are any incorrect answers
      final incorrectQuestions = questionsToReview.where((q) => q.status == QuestionStatus.incorrect).toList();
      
      if (incorrectQuestions.isNotEmpty) {
        // Show InfoScreen for mistakes
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => InfoScreen(
              icon: Icons.quiz,
              descriptionText: "Now let's correct your mistakes",
              buttonText: "Continue",
              onButtonPressed: () {
                Navigator.of(context).pop();
                startReviewMode(incorrectQuestions);
              },
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              );
            },
          ),
        );
      } else {
        // All questions correct, go to finish screen
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const FinishLessonScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              );
            },
          ),
        );
      }
    }
  }

  void startReviewMode(List<QuestionData> incorrectQuestions) {
    setState(() {
      questionsToReview = incorrectQuestions;
      currentQuestionIndex = 0;
      selectedChoiceIndex = null;
      isAnswerRevealed = false;
      isReviewMode = true;
    });
  }

  Color getChoiceBorderColor(int index) {
    if (!isAnswerRevealed) {
      return selectedChoiceIndex == index ? Colors.blue : Colors.grey;
    } else {
      final currentQuestion = questionsToReview[currentQuestionIndex];
      final isCorrectAnswer = currentQuestion.choices[index] == currentQuestion.correctAnswer;
      final isSelectedAnswer = selectedChoiceIndex == index;
      
      if (isCorrectAnswer) {
        return Colors.green;
      } else if (isSelectedAnswer && !isCorrectAnswer) {
        return Colors.red;
      } else {
        return Colors.grey;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questionsToReview[currentQuestionIndex];
    
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
                    '${currentQuestionIndex + 1} / ${questionsToReview.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) / questionsToReview.length,
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Question text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: Text(
                  currentQuestion.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Choices
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion.choices.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => selectChoice(index),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: getChoiceBorderColor(index),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            currentQuestion.choices[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Submit/Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedChoiceIndex != null ? 
                    (isAnswerRevealed ? nextQuestion : submitAnswer) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedChoiceIndex != null ? Colors.blue : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isAnswerRevealed ? 'Continue' : 'Enter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}