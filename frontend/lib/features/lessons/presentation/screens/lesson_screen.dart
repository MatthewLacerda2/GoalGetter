import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/features/lessons/presentation/controllers/lesson_controller.dart';
import 'package:goal_getter/features/lessons/presentation/screens/info_screen.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/lesson_cannot_start.dart';
import 'package:goal_getter/features/lessons/presentation/widgets/lesson_question_view.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The lesson, drawn from the [LessonState] its controller is in. It decides
/// nothing about the lesson's flow: watching the controller opens a lesson,
/// and each state is drawn as it comes, the finished one by handing over to
/// the finish route.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  /// The last question drawn. It stays under the review intro as it slides
  /// in, and under the finish screen as that replaces this one.
  LessonAnswering? _lastQuestion;

  LessonController get _controller =>
      ref.read(lessonControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(lessonControllerProvider);
    ref.listen(
      lessonControllerProvider,
      (previous, next) => _onChanged(previous?.value, next.value),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: lesson.when(
        // A retry opens a new lesson: the spinner, not the old failure.
        skipLoadingOnRefresh: false,
        loading: () => const SafeArea(child: _Spinner()),
        error: (error, _) => SafeArea(child: LessonCannotStart(error)),
        data: (state) => switch (state) {
          LessonNotReady() || LessonNoActiveGoal() => SafeArea(
            child: LessonCannotStart(state),
          ),
          _ => Stack(
            fit: StackFit.expand,
            children: [
              // Only a question being answered takes taps or is read out;
              // one under the review intro or the finish is a backdrop.
              IgnorePointer(
                ignoring: state is! LessonAnswering,
                child: ExcludeSemantics(
                  excluding: state is! LessonAnswering,
                  child: SafeArea(child: _underneath(state)),
                ),
              ),
              _ReviewIntro(
                visible: state is LessonReviewIntro,
                onContinue: _controller.startReview,
              ),
            ],
          ),
        },
      ),
    );
  }

  /// The question being answered, or the spinner while the answers are sent.
  Widget _underneath(LessonState state) {
    if (state is LessonAnswering) _lastQuestion = state;
    final question = state is LessonSubmitting ? null : _lastQuestion;
    if (question == null) return const _Spinner();
    return LessonQuestionPage(
      state: question,
      onSelect: _controller.selectChoice,
      onEnter: _controller.submitAnswer,
      onContinue: _controller.nextQuestion,
    );
  }

  /// The lesson ended, or the answers did not reach the server. The answers
  /// stay on screen either way, so a failed submit is said over them.
  void _onChanged(LessonState? previous, LessonState? next) {
    if (next is LessonFinished && previous is! LessonFinished) {
      context.pushReplacement(
        AppRoutes.lessonFinish,
        extra: next.evaluation,
      );
    }
    final failed = _submitFailure(next);
    if (failed != null && _submitFailure(previous) == null) {
      showFailure(
        context,
        failed,
        title: AppLocalizations.of(context).lessonSubmitFailed,
        onRetry: _controller.retrySubmit,
      );
    }
  }

  Object? _submitFailure(LessonState? state) => switch (state) {
    LessonAnswering(round: FirstRound(:final submitFailure)) => submitFailure,
    _ => null,
  };
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

/// The screen that says the mistakes come next. It slides in from the right
/// over the last answered question and back out over the first one to
/// correct: the transition it had when it was a pushed page.
class _ReviewIntro extends StatelessWidget {
  const _ReviewIntro({required this.visible, required this.onContinue});

  final bool visible;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) => SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut)),
        ),
        child: child,
      ),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      child: visible
          ? InfoScreen(
              key: const ValueKey('review-intro'),
              icon: Icons.quiz,
              descriptionText: l10n.nowLetSCorrectYourMistakes,
              buttonText: l10n.continuate,
              onButtonPressed: onContinue,
            )
          : const SizedBox.shrink(),
    );
  }
}
