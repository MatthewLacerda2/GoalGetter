import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
import 'package:goal_getter/screens/objective/finish_lesson_screen.dart';
import 'package:goal_getter/widgets/screens/objective/lesson/stat_data.dart';
import '../../models/lesson_question_data.dart';
import '../intermediate/info_screen.dart';
import 'dart:async';

class LessonScreen extends StatefulWidget {
  final List<LessonQuestionData> questions;

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
  List<LessonQuestionData> questionsToReview = [];
  bool isReviewMode = false;
  
  // Time tracking variables
  late DateTime _startTime;
  Duration _totalTimeSpent = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    questionsToReview = List.from(widget.questions);
    _startTime = DateTime.now();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalTimeSpent = DateTime.now().difference(_startTime);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  int _calculateLongestStreak() {
    int longestStreak = 0;
    int currentStreak = 0;
    
    for (var question in questionsToReview) {
      if (question.status == LessonQuestionStatus.correct) {
        currentStreak++;
        longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      } else {
        currentStreak = 0;
      }
    }
    
    return longestStreak;
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
        currentQuestion.status = LessonQuestionStatus.correct;
      } else {
        currentQuestion.status = LessonQuestionStatus.incorrect;
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
      final incorrectQuestions = questionsToReview.where((q) => q.status == LessonQuestionStatus.incorrect).toList();
      
      if (incorrectQuestions.isNotEmpty) {
        // Show InfoScreen for mistakes
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => InfoScreen(
              icon: Icons.quiz,
              descriptionText: AppLocalizations.of(context)!.nowLetSCorrectYourMistakes,
              buttonText: AppLocalizations.of(context)!.continuate,
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
        _timer?.cancel(); // Stop the timer
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FinishLessonScreen(
              title: "Finish lesson screen",
              icon: Icons.check_circle,
              timeSpent: StatData(
                title: "Time", 
                icon: Icons.timer, 
                text: _formatDuration(_totalTimeSpent), 
                color: Colors.blue
              ),
              accuracy: StatData(
                title: "Accuracy", 
                icon: Icons.check_circle, 
                text: "${(questionsToReview.where((q) => q.status == LessonQuestionStatus.correct).length / questionsToReview.length * 100).toStringAsFixed(2)}%", 
                color: Colors.green
              ),
              combo: StatData(
                title: "Combo", 
                icon: Icons.star, 
                text: "${_calculateLongestStreak()}", 
                color: Colors.yellow
              )
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
      }
    }
  }

  void startReviewMode(List<LessonQuestionData> incorrectQuestions) {
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
    }
    
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

  Color getButtonColor() {
    if (selectedChoiceIndex == null) {
      return Colors.grey[600]!;
    }
    
    if (!isAnswerRevealed) {
      return Colors.blue;
    } else {
      final currentQuestion = questionsToReview[currentQuestionIndex];
      final isCorrect = currentQuestion.choices[selectedChoiceIndex!] == currentQuestion.correctAnswer;
      return isCorrect ? Colors.green : Colors.red;
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
                      fontWeight: FontWeight.w600,
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[800]!.withValues(alpha: 0.6),
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
                  textAlign: TextAlign.left,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Choices
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion.choices.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: InkWell(
                        onTap: () => selectChoice(index),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[800]!.withValues(alpha: 0.6),
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
                            textAlign: TextAlign.left,
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
                    backgroundColor: getButtonColor(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isAnswerRevealed ? AppLocalizations.of(context)!.continuate : AppLocalizations.of(context)!.enter,
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