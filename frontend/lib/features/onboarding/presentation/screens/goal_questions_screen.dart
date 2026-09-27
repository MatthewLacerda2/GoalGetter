import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/goal_questions_controller.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/question_option_tile.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/question_card.dart';

/// Step 2 of goal creation: one objective question at a time, drawn from its
/// controller. The last answer sends everything to `POST /goals/study-plan`; a
/// failure there keeps every answer, and offers a retry or a way back to
/// change them.
class GoalQuestionsScreen extends ConsumerStatefulWidget {
  final List<ObjectiveQuestion> questions;
  final String prompt;

  const GoalQuestionsScreen({
    super.key,
    required this.prompt,
    required this.questions,
  });

  @override
  ConsumerState<GoalQuestionsScreen> createState() =>
      _GoalQuestionsScreenState();
}

class _GoalQuestionsScreenState extends ConsumerState<GoalQuestionsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _slideController = AnimationController(
    duration: const Duration(milliseconds: 400),
    vsync: this,
  );
  late final _curve = CurvedAnimation(
    parent: _slideController,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0.3, 0.0),
    end: Offset.zero,
  ).animate(_curve);
  late final Animation<double> _fadeAnimation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(_curve);

  GoalQuestionsControllerProvider get _provider =>
      goalQuestionsControllerProvider(widget.prompt, widget.questions);

  GoalQuestionsController get _controller => ref.read(_provider.notifier);

  @override
  void initState() {
    super.initState();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onOptionSelected(String option) {
    if (!_controller.select(option)) return;

    // Brief delay to allow the user to see their selection before auto-advancing
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      ref.read(_provider).isLast ? _controller.requestPlan() : _moveBy(1);
    });
  }

  void _moveBy(int step) {
    _controller.leave();
    _slideController.reverse().then((_) {
      if (!mounted) return;
      _controller.move(step);
      _slideController.forward();
    });
  }

  /// The plan arrived, or its request failed: each is said once.
  void _onChanged(PlanRequest? previous, PlanRequest next) {
    if (next is PlanReady && previous is! PlanReady) {
      context.push(AppRoutes.studyPlan, extra: next.draft).then((_) {
        if (mounted) _controller.resume();
      });
    }
    if (next is PlanFailed && previous is! PlanFailed) {
      showFailure(
        context,
        next.error,
        title: AppLocalizations.of(context).onboardingPlanFailed,
        onRetry: _controller.requestPlan,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(_provider);
    ref.listen(
      _provider,
      (previous, next) => _onChanged(previous?.plan, next.plan),
    );
    final isLoading = state.plan is PlanLoading;
    final progress = widget.questions.isNotEmpty
        ? (state.index + 1) / widget.questions.length
        : 0.0;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.questions),
        centerTitle: true,
        leading: state.index > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: isLoading ? null : () => _moveBy(-1),
                tooltip: l10n.onboardingPreviousQuestion,
              )
            : null,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(
                '${state.index + 1}/${widget.questions.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(AppSizes.progressBar),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: scheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            minHeight: AppSizes.progressBar,
          ),
        ),
      ),
      body: isLoading
          ? _Generating(label: l10n.onboardingGeneratingPlan)
          : _questionView(state),
    );
  }

  Widget _questionView(GoalQuestionsState state) {
    final question = widget.questions[state.index];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuestionCard(question: question.question),
              const SizedBox(height: AppSpacing.xl),
              for (final option in question.options)
                QuestionOptionTile(
                  option: option,
                  isSelected: state.answers[state.index] == option,
                  onTap: () => _onOptionSelected(option),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Generating extends StatelessWidget {
  const _Generating({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.xl),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
