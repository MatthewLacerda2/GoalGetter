import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/stat_data.dart';

import 'package:goal_getter/features/lessons/domain/lesson_models.dart';
import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/lesson_failure_view.dart';
import 'package:goal_getter/features/lessons/presentation/screens/info_screen.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/lesson_controller.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame: start() writes to the provider, and
    // Riverpod forbids modifying a provider while the widget tree is building.
    // Calling it directly here threw, and because start() is an unawaited
    // async call the error was swallowed, leaving the spinner forever.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(lessonControllerProvider.notifier).start();
    });
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
      context.pushReplacement(
        AppRoutes.lessonFinish,
        extra: _finishArgs(state),
      );
    }
  }

  /// The server's evaluation. When it was lost (LessonEvaluation.elo is null)
  /// the elo change is unknown and shows as a dash.
  FinishLessonArgs _finishArgs(LessonState state) {
    final l10n = AppLocalizations.of(context)!;
    final evaluation = state.evaluationResponse;
    final elo = evaluation?.elo;
    return FinishLessonArgs(
      title: l10n.lessonFinishedTitle,
      icon: Icons.check_circle,
      timeSpent: StatData(
        title: l10n.lessonTime,
        icon: Icons.timer,
        text: _formatDuration(evaluation != null
            ? Duration(seconds: evaluation.totalSecondsSpent)
            : state.totalTimeSpent),
        color: Theme.of(context).colorScheme.primary,
      ),
      accuracy: StatData(
        title: l10n.lessonAccuracy,
        icon: Icons.check_circle,
        text: '${(evaluation?.studentAccuracy ?? 0).toStringAsFixed(0)}%',
        color: Theme.of(context).extension<CustomColors>()?.success ?? Colors.green,
      ),
      elo: StatData(
        title: l10n.elo,
        icon: Icons.trending_up,
        text: elo == null ? '—' : '${elo >= 0 ? '+' : ''}$elo',
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
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
      return (Theme.of(context).extension<CustomColors>()?.success ?? Colors.green).withValues(alpha: 0.2);
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
    return isCorrect ? (Theme.of(context).extension<CustomColors>()?.success ?? Colors.green) : Theme.of(context).colorScheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonControllerProvider);

    ref.listen<LessonState>(lessonControllerProvider, (previous, next) {
      if (next.isCompleted && !(previous?.isCompleted ?? false)) {
        _handleCompletion(next);
      }
    });

    final controller = ref.read(lessonControllerProvider.notifier);
    final Widget? blocker;
    if (state.isLoading || state.isSubmitting) {
      blocker = Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (state.startFailure != null) {
      blocker = LessonStartFailureView(
        failure: state.startFailure!,
        onRetry: controller.start,
      );
    } else if (state.submitFailure != null) {
      blocker = LessonSubmitFailureView(
        failure: state.submitFailure!,
        onRetry: controller.retrySubmit,
      );
    } else {
      blocker = null;
    }
    if (blocker != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(child: blocker),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
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
