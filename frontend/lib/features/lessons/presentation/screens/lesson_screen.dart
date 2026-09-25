import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/stat_data.dart';

import 'package:goal_getter/features/lessons/domain/lesson_models.dart';
import 'package:goal_getter/app/theme/app_theme.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/core/widgets/state_message.dart';
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
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => InfoScreen(
            icon: Icons.quiz,
            descriptionText:
                AppLocalizations.of(context).nowLetSCorrectYourMistakes,
            buttonText: AppLocalizations.of(context).continuate,
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

  /// The server's evaluation. Without one - the review round, which is never
  /// submitted - the elo shows as a dash and the time is the app's own count.
  FinishLessonArgs _finishArgs(LessonState state) {
    final l10n = AppLocalizations.of(context);
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
  /// the lesson loads or an answer is in flight, or a lesson that never
  /// opened. A failed submit is not here - the answers are still on screen,
  /// so it is a snackbar (see [build]).
  Widget? _blocker(LessonState state, LessonController controller) {
    if (state.isLoading || state.isSubmitting) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    final failure = state.startFailure;
    if (failure != null) return _cannotStart(failure, controller.start);
    return null;
  }

  /// The lesson could not open: the question bank is still being built (409),
  /// there is no active goal, or the call failed and can be tried again. The
  /// first two are states, not failures; only the third is a [FailureView].
  Widget _cannotStart(
    LessonFailure<LessonStartFailureKind> failure,
    VoidCallback onRetry,
  ) {
    final l10n = AppLocalizations.of(context);
    final Widget message = switch (failure.kind) {
      LessonStartFailureKind.notReady => StateMessage(
        icon: Icons.hourglass_top,
        title: l10n.lessonsStillPreparing,
        body: l10n.lessonsStillPreparingBody,
        actionLabel: l10n.checkAgain,
        onAction: onRetry,
      ),
      LessonStartFailureKind.noActiveGoal => StateMessage(
        icon: Icons.flag_outlined,
        title: l10n.noActiveGoal,
        body: l10n.lessonNoActiveGoalBody,
        actionLabel: l10n.lessonPickGoal,
        onAction: () => context.go(AppRoutes.goals),
      ),
      LessonStartFailureKind.failed => FailureView(
        error: failure.cause,
        title: l10n.lessonStartFailed,
        onRetry: onRetry,
      ),
    };
    return Column(
      children: [
        Expanded(child: message),
        TextButton(
          onPressed: () => context.go(AppRoutes.home),
          child: Text(l10n.lessonBackHome),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
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

  /// The lesson ended, or the answers did not reach the server. The answers
  /// stay on screen either way, so a failed submit is said over them.
  void _onStateChanged(
    LessonState? previous,
    LessonState next,
    LessonController controller,
  ) {
    if (next.isCompleted && !(previous?.isCompleted ?? false)) {
      _handleCompletion(next);
    }
    final failed = next.submitFailure;
    if (failed != null && previous?.submitFailure == null) {
      showFailure(
        context,
        failed.cause,
        title: AppLocalizations.of(context).lessonSubmitFailed,
        onRetry: controller.retrySubmit,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lessonControllerProvider);
    final controller = ref.read(lessonControllerProvider.notifier);

    ref.listen<LessonState>(
      lessonControllerProvider,
      (previous, next) => _onStateChanged(previous, next, controller),
    );

    final blocker = _blocker(state, controller);
    if (blocker != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(child: blocker),
      );
    }

    final currentQuestion = state.questions[state.currentQuestionIndex];
    final l10n = AppLocalizations.of(context);

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
