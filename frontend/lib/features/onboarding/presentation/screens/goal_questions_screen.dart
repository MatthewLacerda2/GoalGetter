import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/question_option_tile.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/step_error.dart';

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
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  Object? _error;

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
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _onOptionSelected(String option) {
    if (_isLoading) return;
    setState(() => _answers[_currentQuestionIndex] = option);

    // Brief delay to allow the user to see their selection before auto-advancing
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _isLast ? _requestStudyPlan() : _moveBy(1);
    });
  }

  void _moveBy(int step) {
    _slideController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _currentQuestionIndex += step);
      _slideController.forward();
    });
  }

  void _backToQuestions() => setState(() => _error = null);

  Future<void> _requestStudyPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final answers = [
      for (var i = 0; i < widget.questions.length; i++)
        ObjectiveAnswer(
          question: widget.questions[i].question,
          answer: _answers[i],
        ),
    ];
    try {
      final plan = await ref
          .read(onboardingApiProvider)
          .studyPlan(widget.prompt, answers);
      if (mounted) {
        context.push(
          AppRoutes.studyPlan,
          extra: GoalDraft(prompt: widget.prompt, answers: answers, plan: plan),
        );
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e);
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
        leading: _currentQuestionIndex > 0 && _error == null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _isLoading ? null : () => _moveBy(-1),
                tooltip: l10n.onboardingPreviousQuestion,
              )
            : null,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
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
          : _error != null
          ? _PlanFailed(
              error: _error!,
              onRetry: _requestStudyPlan,
              onBack: _backToQuestions,
            )
          : _questionView(),
    );
  }

  Widget _questionView() {
    final question = widget.questions[_currentQuestionIndex];
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
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

/// The study plan could not be generated: why, a retry with the same
/// answers, and a way back to change them.
class _PlanFailed extends StatelessWidget {
  const _PlanFailed({
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.onboardingPlanFailed,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            StepError(error: error, onRetry: onRetry),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBack,
              child: Text(l10n.onboardingReviewAnswers),
            ),
          ],
        ),
      ),
    );
  }
}
