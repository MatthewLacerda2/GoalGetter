import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/question_timer.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/question_option_tile.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// Step 2 of goal creation: one objective question at a time. The last answer
/// sends everything to `POST /goals/study-plan`; a failure there keeps every
/// answer, and offers a retry or a way back to change them.
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
  late final List<String> _answers = List.filled(widget.questions.length, '');
  late final QuestionTimer _timer = QuestionTimer(widget.questions.length);
  int _currentQuestionIndex = 0;
  bool _isLoading = false;

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

  bool get _isLast => _currentQuestionIndex == widget.questions.length - 1;

  @override
  void initState() {
    super.initState();
    _timer.show(0);
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onOptionSelected(String option) {
    if (_isLoading) return;
    _timer.stop();
    setState(() => _answers[_currentQuestionIndex] = option);

    // Brief delay to allow the user to see their selection before auto-advancing
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _isLast ? _requestStudyPlan() : _moveBy(1);
    });
  }

  void _moveBy(int step) {
    _timer.stop();
    _slideController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _currentQuestionIndex += step);
      _timer.show(_currentQuestionIndex);
      _slideController.forward();
    });
  }

  Future<void> _requestStudyPlan() async {
    setState(() => _isLoading = true);
    final answers = [
      for (var i = 0; i < widget.questions.length; i++)
        ObjectiveAnswer(
          question: widget.questions[i].question,
          answer: _answers[i],
          totalSeconds: _timer.secondsOn(i),
        ),
    ];
    try {
      final plan = await ref
          .read(onboardingApiProvider)
          .studyPlan(widget.prompt, answers);
      if (mounted) {
        // Back from the plan, he is on the last question again: its clock
        // resumes, in case he changes that answer.
        context
            .push(
              AppRoutes.studyPlan,
              extra: GoalDraft(
                prompt: widget.prompt,
                answers: answers,
                plan: plan,
              ),
            )
            .then((_) {
              if (mounted) _timer.show(_currentQuestionIndex);
            });
      }
    } on Exception catch (e) {
      // Every answer is still in `_answers`, so the retry sends the same ones.
      if (mounted) {
        showFailure(
          context,
          e,
          title: AppLocalizations.of(context).onboardingPlanFailed,
          onRetry: _requestStudyPlan,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final progress = widget.questions.isNotEmpty
        ? (_currentQuestionIndex + 1) / widget.questions.length
        : 0.0;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(l10n.questions),
        centerTitle: true,
        leading: _currentQuestionIndex > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isLoading ? null : () => _moveBy(-1),
                tooltip: l10n.onboardingPreviousQuestion,
              )
            : null,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(
                '${_currentQuestionIndex + 1}/${widget.questions.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: scheme.surfaceContainer,
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            minHeight: 6,
          ),
        ),
      ),
      body: _isLoading
          ? _Generating(label: l10n.onboardingGeneratingPlan)
          : _questionView(),
    );
  }

  Widget _questionView() {
    final question = widget.questions[_currentQuestionIndex];
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Text(
                  question.question,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              for (final option in question.options)
                QuestionOptionTile(
                  option: option,
                  isSelected: _answers[_currentQuestionIndex] == option,
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
          const SizedBox(height: 24),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
