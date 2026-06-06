import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:goal_getter/screens/objective/finish_lesson_screen.dart';
import 'package:goal_getter/widgets/screens/objective/lesson/stat_data.dart';

import '../../models/lesson_question_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_retry_widget.dart';
import '../intermediate/info_screen.dart';
import 'lesson_controller.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final List<LessonQuestionData>? questions;

  LessonScreen({super.key, this.questions});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(lessonControllerProvider.notifier).init(widget.questions);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _handleCompletion(LessonState state) {
    final incorrectQuestions = state.questions
        .where((q) => q.status == LessonQuestionStatus.incorrect)
        .toList();

    if (incorrectQuestions.isNotEmpty && !state.isReviewMode) {
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
              ref.read(lessonControllerProvider.notifier).startReviewMode(incorrectQuestions);
            },
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            );
          },
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => FinishLessonScreen(
            title: "Finish lesson screen",
            icon: Icons.check_circle,
            timeSpent: StatData(
              title: "Time",
              icon: Icons.timer,
              text: state.evaluationResponse != null
                  ? _formatDuration(
                      Duration(seconds: state.evaluationResponse!.totalSecondsSpent),
                    )
                  : _formatDuration(state.totalTimeSpent),
              color: Theme.of(context).colorScheme.primary,
            ),
            accuracy: StatData(
              title: "Accuracy",
              icon: Icons.check_circle,
              text: state.evaluationResponse != null
                  ? "${state.evaluationResponse!.studentAccuracy.toStringAsFixed(2)}%"
                  : "${(state.questions.where((q) => q.status == LessonQuestionStatus.correct).length / state.questions.length * 100).toStringAsFixed(2)}%",
              color: Theme.of(context).extension<CustomColors>()!.success,
            ),
            combo: StatData(
              title: "Combo",
              icon: Icons.star,
              text: "${ref.read(lessonControllerProvider.notifier).calculateLongestStreak()}",
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: Offset(1.0, 0.0),
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

  Color getChoiceFillColor(LessonState state, int index) {
    if (!state.isAnswerRevealed) {
      return state.selectedChoiceIndex == index
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
          : Theme.of(context).colorScheme.outline.withValues(alpha: 0.12);
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isCorrectAnswer =
        index == currentQuestion.apiQuestion.correctAnswerIndex;
    final isSelectedAnswer = state.selectedChoiceIndex == index;

    if (isCorrectAnswer) {
      return Theme.of(context).extension<CustomColors>()!.success.withValues(alpha: 0.2);
    }
    if (isSelectedAnswer && !isCorrectAnswer) {
      return Theme.of(context).colorScheme.error.withValues(alpha: 0.2);
    }
    return Theme.of(context).colorScheme.outline.withValues(alpha: 0.12);
  }

  Color getButtonColor(LessonState state) {
    if (state.selectedChoiceIndex == null) {
      return Theme.of(context).colorScheme.outline;
    }

    if (!state.isAnswerRevealed) {
      return Theme.of(context).colorScheme.primary;
    }
    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isCorrect =
        state.selectedChoiceIndex == currentQuestion.apiQuestion.correctAnswerIndex;
    return isCorrect ? Theme.of(context).extension<CustomColors>()!.success : Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonControllerProvider);

    ref.listen<LessonState>(lessonControllerProvider, (previous, next) {
      if (next.isCompleted && !(previous?.isCompleted ?? false)) {
        _handleCompletion(next);
      }
    });

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: ErrorRetryWidget(
            errorMessage: state.errorMessage!,
            onRetry: () {
              if (widget.questions == null) {
                ref.read(lessonControllerProvider.notifier).init(null);
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
    }

    if (state.questions.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Center(
            child: Text(
              'No questions available',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        ),
      );
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${state.currentQuestionIndex + 1} / ${state.questions.length}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (state.currentQuestionIndex + 1) /
                          state.questions.length,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(20.0),
                ),
                child: Text(
                  currentQuestion.apiQuestion.question,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion.apiQuestion.choices.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: InkWell(
                        onTap: () => ref
                            .read(lessonControllerProvider.notifier)
                            .selectChoice(index),
                        borderRadius: BorderRadius.circular(
                            20.0),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                              16.0),
                          decoration: BoxDecoration(
                            color: getChoiceFillColor(state, index),
                            borderRadius: BorderRadius.circular(
                                20.0),
                          ),
                          child: Text(
                            currentQuestion.apiQuestion.choices[index],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18.0,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.selectedChoiceIndex != null
                      ? (state.isAnswerRevealed
                          ? () => ref.read(lessonControllerProvider.notifier).nextQuestion()
                          : () => ref.read(lessonControllerProvider.notifier).submitAnswer())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getButtonColor(state),
                    padding: EdgeInsets.symmetric(
                        vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          20.0),
                    ),
                  ),
                  child: Text(
                    state.isAnswerRevealed
                        ? AppLocalizations.of(context)!.continuate
                        : AppLocalizations.of(context)!.enter,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}
