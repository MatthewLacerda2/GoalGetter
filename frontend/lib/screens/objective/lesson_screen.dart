import 'dart:async';

import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
import 'package:goal_getter/screens/objective/finish_lesson_screen.dart';
import 'package:goal_getter/widgets/screens/objective/lesson/stat_data.dart';
import 'package:openapi/api.dart';

import '../../models/lesson_question_data.dart';
import '../../services/auth_service.dart';
import '../../services/openapi_client_factory.dart';
import '../../theme/app_theme.dart';
import '../intermediate/info_screen.dart';

class LessonScreen extends StatefulWidget {
  final List<LessonQuestionData>? questions;

  const LessonScreen({super.key, this.questions});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _QuestionData {
  final MultipleChoiceQuestionResponse apiQuestion;
  LessonQuestionStatus status;
  DateTime? startTime;
  int? studentAnswerIndex;
  int? secondsSpent;

  _QuestionData({required this.apiQuestion})
    : status = LessonQuestionStatus.notAnswered,
      startTime = null,
      studentAnswerIndex = null,
      secondsSpent = null;
}

class _LessonScreenState extends State<LessonScreen> {
  final _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;

  int currentQuestionIndex = 0;
  int? selectedChoiceIndex;
  bool isAnswerRevealed = false;
  List<_QuestionData> questionsToReview = [];
  bool isReviewMode = false;
  bool _hasSubmittedAnswers = false;

  // Time tracking variables
  late DateTime _startTime;
  Duration _totalTimeSpent = Duration.zero;
  Timer? _timer;

  // Store API response data
  MultipleChoiceActivityEvaluationResponse? _evaluationResponse;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _startTimer();

    if (widget.questions != null && widget.questions!.isNotEmpty) {
      // Legacy mode: use provided questions
      _initializeFromQuestions(widget.questions!);
    } else {
      // New mode: fetch from API
      _fetchQuestions();
    }
  }

  void _initializeFromQuestions(List<LessonQuestionData> questions) {
    // Convert legacy format to new format
    // Note: This is for backwards compatibility only
    setState(() {
      _isLoading = false;
      questionsToReview = questions.map((q) {
        // Create a dummy API question for legacy support
        // This won't work for submission but maintains UI compatibility
        final dummyApiQuestion = MultipleChoiceQuestionResponse(
          id: '',
          question: q.question,
          choices: q.choices,
          correctAnswerIndex: q.choices.indexOf(q.correctAnswer),
        );
        return _QuestionData(apiQuestion: dummyApiQuestion);
      }).toList();
      if (questionsToReview.isNotEmpty) {
        questionsToReview[0].startTime = DateTime.now();
      }
    });
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createWithAccessToken();

      final activitiesApi = ActivitiesApi(apiClient);
      final response = await activitiesApi
          .takeMultipleChoiceActivityApiV1ActivitiesPost();

      if (response == null || response.questions.isEmpty) {
        throw Exception('No questions available');
      }

      if (mounted) {
        setState(() {
          questionsToReview = response.questions.map((q) {
            return _QuestionData(apiQuestion: q);
          }).toList();
          if (questionsToReview.isNotEmpty) {
            questionsToReview[0].startTime = DateTime.now();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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
        longestStreak = currentStreak > longestStreak
            ? currentStreak
            : longestStreak;
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
      currentQuestion.studentAnswerIndex = selectedChoiceIndex;

      // Calculate time spent on this question
      if (currentQuestion.startTime != null) {
        final timeSpent = DateTime.now().difference(currentQuestion.startTime!);
        currentQuestion.secondsSpent = timeSpent.inSeconds.clamp(2, 3600);
      } else {
        currentQuestion.secondsSpent = 2; // Minimum required by API
      }

      final isCorrect =
          selectedChoiceIndex == currentQuestion.apiQuestion.correctAnswerIndex;

      if (isCorrect) {
        currentQuestion.status = LessonQuestionStatus.correct;
      } else {
        currentQuestion.status = LessonQuestionStatus.incorrect;
      }
    });
  }

  Future<void> _submitAnswers() async {
    if (_hasSubmittedAnswers) return;

    try {
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createWithAccessToken();

      final activitiesApi = ActivitiesApi(apiClient);

      // Build answer list from first pass (before review mode)
      final answers = questionsToReview
          .where((q) => q.studentAnswerIndex != null && q.secondsSpent != null)
          .map(
            (q) => MultipleChoiceQuestionAnswer(
              id: q.apiQuestion.id,
              studentAnswerIndex: q.studentAnswerIndex!,
              secondsSpent: q.secondsSpent!,
            ),
          )
          .toList();

      if (answers.isEmpty) {
        throw Exception('No answers to submit');
      }

      final request = MultipleChoiceActivityEvaluationRequest(answers: answers);
      final response = await activitiesApi
          .takeMultipleChoiceActivityApiV1ActivitiesEvaluatePost(request);

      if (mounted) {
        setState(() {
          _evaluationResponse = response;
          _hasSubmittedAnswers = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  void nextQuestion() {
    if (currentQuestionIndex < questionsToReview.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedChoiceIndex = null;
        isAnswerRevealed = false;
        // Start timer for next question
        questionsToReview[currentQuestionIndex].startTime = DateTime.now();
      });
    } else {
      // All questions answered - submit to API if not in review mode
      if (!isReviewMode && !_hasSubmittedAnswers) {
        _submitAnswers().then((_) {
          _handleCompletion();
        });
      } else {
        _handleCompletion();
      }
    }
  }

  void _handleCompletion() {
    // Check if there are any incorrect answers
    final incorrectQuestions = questionsToReview
        .where((q) => q.status == LessonQuestionStatus.incorrect)
        .toList();

    if (incorrectQuestions.isNotEmpty && !isReviewMode) {
      // Show InfoScreen for mistakes
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => InfoScreen(
            icon: Icons.quiz,
            descriptionText: AppLocalizations.of(
              context,
            )!.nowLetSCorrectYourMistakes,
            buttonText: AppLocalizations.of(context)!.continuate,
            onButtonPressed: () {
              Navigator.of(context).pop();
              startReviewMode(incorrectQuestions);
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        ),
      );
    } else {
      // All questions correct or review complete, go to finish screen
      _timer?.cancel();
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => FinishLessonScreen(
            title: "Finish lesson screen",
            icon: Icons.check_circle,
            timeSpent: StatData(
              title: "Time",
              icon: Icons.timer,
              text: _evaluationResponse != null
                  ? _formatDuration(
                      Duration(seconds: _evaluationResponse!.totalSecondsSpent),
                    )
                  : _formatDuration(_totalTimeSpent),
              color: AppTheme.accentPrimary,
            ),
            accuracy: StatData(
              title: "Accuracy",
              icon: Icons.check_circle,
              text: _evaluationResponse != null
                  ? "${_evaluationResponse!.studentAccuracy.toStringAsFixed(2)}%"
                  : "${(questionsToReview.where((q) => q.status == LessonQuestionStatus.correct).length / questionsToReview.length * 100).toStringAsFixed(2)}%",
              color: AppTheme.success,
            ),
            combo: StatData(
              title: "Combo",
              icon: Icons.star,
              text: "${_calculateLongestStreak()}",
              color: AppTheme.accentSecondary,
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        ),
      );
    }
  }

  void startReviewMode(List<_QuestionData> incorrectQuestions) {
    setState(() {
      questionsToReview = incorrectQuestions;
      currentQuestionIndex = 0;
      selectedChoiceIndex = null;
      isAnswerRevealed = false;
      isReviewMode = true;
      if (questionsToReview.isNotEmpty) {
        questionsToReview[0].startTime = DateTime.now();
      }
    });
  }

  Color getChoiceFillColor(int index) {
    if (!isAnswerRevealed) {
      return selectedChoiceIndex == index
          ? AppTheme.accentPrimary.withValues(alpha: 0.2)
          : AppTheme.textTertiary.withValues(alpha: 0.12);
    }

    final currentQuestion = questionsToReview[currentQuestionIndex];
    final isCorrectAnswer =
        index == currentQuestion.apiQuestion.correctAnswerIndex;
    final isSelectedAnswer = selectedChoiceIndex == index;

    if (isCorrectAnswer) {
      return AppTheme.success.withValues(alpha: 0.2);
    }
    if (isSelectedAnswer && !isCorrectAnswer) {
      return AppTheme.error.withValues(alpha: 0.2);
    }
    return AppTheme.textTertiary.withValues(alpha: 0.12);
  }

  Color getButtonColor() {
    if (selectedChoiceIndex == null) {
      return AppTheme.textTertiary;
    }

    if (!isAnswerRevealed) {
      return AppTheme.accentPrimary;
    }
    final currentQuestion = questionsToReview[currentQuestionIndex];
    final isCorrect =
        selectedChoiceIndex == currentQuestion.apiQuestion.correctAnswerIndex;
    return isCorrect ? AppTheme.success : AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: AppTheme.accentPrimary,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: $_errorMessage',
                  style: const TextStyle(color: AppTheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing16),
                ElevatedButton(
                  onPressed: () {
                    if (widget.questions == null) {
                      _fetchQuestions();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questionsToReview.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const SafeArea(
          child: Center(
            child: Text(
              'No questions available',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ),
      );
    }

    final currentQuestion = questionsToReview[currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.edgePadding),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${currentQuestionIndex + 1} / ${questionsToReview.length}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSize16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (currentQuestionIndex + 1) /
                          questionsToReview.length,
                      backgroundColor: AppTheme.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.edgePadding),
                decoration: BoxDecoration(
                  color: AppTheme.textTertiary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppTheme.cardRadius),
                ),
                child: Text(
                  currentQuestion.apiQuestion.question,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontSize20,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion.apiQuestion.choices.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: InkWell(
                        onTap: () => selectChoice(index),
                        borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                              AppTheme.spacing16),
                          decoration: BoxDecoration(
                            color: getChoiceFillColor(index),
                            borderRadius: BorderRadius.circular(
                                AppTheme.cardRadius),
                          ),
                          child: Text(
                            currentQuestion
                                .apiQuestion.choices[index],
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontSize18,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedChoiceIndex != null
                      ? (isAnswerRevealed
                          ? nextQuestion
                          : submitAnswer)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getButtonColor(),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius),
                    ),
                  ),
                  child: Text(
                    isAnswerRevealed
                        ? AppLocalizations.of(context)!.continuate
                        : AppLocalizations.of(context)!.enter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppTheme.fontSize20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
            ],
          ),
        ),
      ),
    );
  }
}
