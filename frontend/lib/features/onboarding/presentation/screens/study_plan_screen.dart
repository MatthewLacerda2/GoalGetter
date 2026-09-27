import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/study_plan_controller.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/loading_button.dart';

/// Step 3 of goal creation: the goal's name, a short AI-generated summary of
/// what the student will study (markdown), and confirm / start over.
///
/// Confirming is its controller's: `POST /goals`, which needs a session.
/// Without one the draft is held and the student goes to sign in; the sign-in
/// brings them back here (see `SignInLanding`). On success the goal is stored
/// as active and the standard questions fill the wait while its first lesson
/// generates (#132).
class StudyPlanScreen extends ConsumerStatefulWidget {
  final GoalDraft draft;

  const StudyPlanScreen({super.key, required this.draft});

  @override
  ConsumerState<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends ConsumerState<StudyPlanScreen> {
  StudyPlanControllerProvider get _provider =>
      studyPlanControllerProvider(widget.draft);

  StudyPlanController get _controller => ref.read(_provider.notifier);

  void _onChanged(StudyPlanState next) {
    switch (next) {
      case PlanNeedsSignIn():
        context.go(AppRoutes.start);
      case PlanCommitted(:final goal):
        context.go(
          AppRoutes.standardQuestions,
          extra: StandardQuestionsArgs(
            goalId: goal.id,
            questions: goal.standardQuestions,
          ),
        );
      // The plan is untouched on screen, so the failure goes over it - at the
      // top, where it does not cover the two buttons that failed.
      case PlanCommitFailed(:final error):
        showFailure(
          context,
          error,
          onRetry: _controller.confirm,
          position: FailurePosition.top,
        );
      case PlanShown() || PlanCommitting():
        break;
    }
  }

  void _startOver() {
    _controller.startOver();
    context.go(AppRoutes.goalPrompt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = widget.draft.plan;
    final isLoading = ref.watch(_provider) is PlanCommitting;
    ref.listen(_provider, (_, next) => _onChanged(next));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.studyPlan)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        plan.goalName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: AppType.headingHeight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _Description(markdown: plan.description),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Actions(
                isLoading: isLoading,
                onConfirm: isLoading ? null : _controller.confirm,
                onDeny: isLoading ? null : _startOver,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Description extends StatelessWidget {
  final String markdown;

  const _Description({required this.markdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge?.copyWith(
      height: AppType.readingHeight,
    );

    return MarkdownBody(
      data: markdown,
      styleSheet: MarkdownStyleSheet(
        p: body,
        listBullet: body,
        strong: body?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        blockSpacing: AppSpacing.gap10,
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onConfirm;
  final VoidCallback? onDeny;

  const _Actions({
    required this.isLoading,
    required this.onConfirm,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.titleSmall;

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: onDeny,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.secondary,
              foregroundColor: scheme.onSecondary,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
            child: Text(
              l10n.startOver,
              style: label?.copyWith(color: scheme.onSecondary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: LoadingButton(
            label: l10n.startLearning,
            isLoading: isLoading,
            onPressed: onConfirm,
          ),
        ),
      ],
    );
  }
}
