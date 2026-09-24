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
import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/lesson_question_view.dart';

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
        color:
            Theme.of(context).extension<CustomColors>()?.success ??
            AppTheme.success,
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
      final success =
          Theme.of(context).extension<CustomColors>()?.success ??
          AppTheme.success;
      return success.withValues(alpha: 0.2);
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
    final success =
        Theme.of(context).extension<CustomColors>()?.success ??
        AppTheme.success;
    return isCorrect ? success : Theme.of(context).colorScheme.error;
  }

  /// What takes the whole screen instead of the question: the spinner while
  /// the lesson loads or an answer is in flight, or a failure with its retry.
  Widget? _blocker(LessonState state, LessonController controller) {
    if (state.isLoading || state.isSubmitting) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (state.startFailure != null) {
      return LessonStartFailureView(
        failure: state.startFailure!,
        onRetry: controller.start,
      );
    }
    if (state.submitFailure != null) {
      return LessonSubmitFailureView(
        failure: state.submitFailure!,
        onRetry: controller.retrySubmit,
      );
    }
    return null;
  }

  /// The answers, one tile each; the fill colour says how each one stands.
  Widget _choices(LessonState state, LessonQuestionState question) {
    return ListView.builder(
      itemCount: question.apiQuestion.choices.length,
      itemBuilder: (context, index) => LessonChoiceTile(
        label: question.apiQuestion.choices[index],
        fill: getChoiceFillColor(state, index),
        onTap: () => ref
            .read(lessonControllerProvider.notifier)
            .selectChoice(index),
      ),
    );
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
    final blocker = _blocker(state, controller);
    if (blocker != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(child: blocker),
      );
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              LessonProgressRow(
                index: state.currentQuestionIndex,
                total: state.questions.length,
              ),
              SizedBox(height: 32),
              LessonQuestionCard(
                question: currentQuestion.apiQuestion.question,
              ),
              SizedBox(height: 40),
              Expanded(child: _choices(state, currentQuestion)),
              SizedBox(height: 16.0),
              LessonAnswerButton(
                label: state.isAnswerRevealed ? l10n.continuate : l10n.enter,
                color: getButtonColor(state),
                onPressed: state.selectedChoiceIndex == null
                    ? null
                    : (state.isAnswerRevealed
                          ? controller.nextQuestion
                          : controller.submitAnswer),
              ),
              SizedBox(height: 8.0),
            ],
          ),
        ),
      ),
    );
  }
}
