import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
import 'package:goal_getter/screens/objective/finish_lesson_screen.dart';
import 'package:goal_getter/widgets/screens/objective/lesson/stat_data.dart';

import '../../models/lesson_question_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_retry_widget.dart';
import '../intermediate/info_screen.dart';
import 'lesson_controller.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final List<LessonQuestionData>? questions;

  const LessonScreen({super.key, this.questions});

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
              color: AppTheme.accentPrimary,
            ),
            accuracy: StatData(
              title: "Accuracy",
              icon: Icons.check_circle,
              text: state.evaluationResponse != null
                  ? "${state.evaluationResponse!.studentAccuracy.toStringAsFixed(2)}%"
                  : "${(state.questions.where((q) => q.status == LessonQuestionStatus.correct).length / state.questions.length * 100).toStringAsFixed(2)}%",
              color: AppTheme.success,
            ),
            combo: StatData(
              title: "Combo",
              icon: Icons.star,
              text: "${ref.read(lessonControllerProvider.notifier).calculateLongestStreak()}",
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

  Color getChoiceFillColor(LessonState state, int index) {
    if (!state.isAnswerRevealed) {
      return state.selectedChoiceIndex == index
          ? AppTheme.accentPrimary.withValues(alpha: 0.2)
          : AppTheme.textTertiary.withValues(alpha: 0.12);
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isCorrectAnswer =
        index == currentQuestion.apiQuestion.correctAnswerIndex;
    final isSelectedAnswer = state.selectedChoiceIndex == index;

    if (isCorrectAnswer) {
      return AppTheme.success.withValues(alpha: 0.2);
    }
    if (isSelectedAnswer && !isCorrectAnswer) {
      return AppTheme.error.withValues(alpha: 0.2);
    }
    return AppTheme.textTertiary.withValues(alpha: 0.12);
  }

  Color getButtonColor(LessonState state) {
    if (state.selectedChoiceIndex == null) {
      return AppTheme.textTertiary;
    }

    if (!state.isAnswerRevealed) {
      return AppTheme.accentPrimary;
    }
    final currentQuestion = state.questions[state.currentQuestionIndex];
    final isCorrect =
        state.selectedChoiceIndex == currentQuestion.apiQuestion.correctAnswerIndex;
    return isCorrect ? AppTheme.success : AppTheme.error;
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
      return const Scaffold(
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

    if (state.errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
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
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Center(
            child: Text(
              'No questions available',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ),
      );
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];

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
                    '${state.currentQuestionIndex + 1} / ${state.questions.length}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSize16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (state.currentQuestionIndex + 1) /
                          state.questions.length,
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
                        onTap: () => ref
                            .read(lessonControllerProvider.notifier)
                            .selectChoice(index),
                        borderRadius: BorderRadius.circular(
                            AppTheme.cardRadius),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                              AppTheme.spacing16),
                          decoration: BoxDecoration(
                            color: getChoiceFillColor(state, index),
                            borderRadius: BorderRadius.circular(
                                AppTheme.cardRadius),
                          ),
                          child: Text(
                            currentQuestion.apiQuestion.choices[index],
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
                  onPressed: state.selectedChoiceIndex != null
                      ? (state.isAnswerRevealed
                          ? () => ref.read(lessonControllerProvider.notifier).nextQuestion()
                          : () => ref.read(lessonControllerProvider.notifier).submitAnswer())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: getButtonColor(state),
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppTheme.cardRadius),
                    ),
                  ),
                  child: Text(
                    state.isAnswerRevealed
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
