import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/goal_prompt_controller.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/loading_button.dart';

/// Step 1 of goal creation: what the student wants to learn. Its controller
/// sends it to `POST /goals/objective-questions`; a 400 there is Gemini saying
/// it is not a goal, and its reasoning is shown here so the student can
/// rephrase.
class GoalPromptScreen extends ConsumerStatefulWidget {
  const GoalPromptScreen({super.key});

  @override
  ConsumerState<GoalPromptScreen> createState() => _GoalPromptScreenState();
}

class _GoalPromptScreenState extends ConsumerState<GoalPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();

  final _promptFocusNode = FocusNode();

  GoalPromptController get _controller =>
      ref.read(goalPromptControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _promptFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _promptController.dispose();
    _promptFocusNode.dispose();
    super.dispose();
  }

  void _onEnterPressed() => _controller.ask(_promptController.text);

  /// Each outcome of a send, said once as it arrives.
  void _onChanged(GoalPromptState next) {
    switch (next) {
      case PromptTooShort():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).beDetailedOfYourGoal),
          ),
        );
      case PromptAccepted(:final prompt, :final questions):
        context.push(
          AppRoutes.goalQuestions,
          extra: GoalQuestionsArgs(prompt: prompt, questions: questions),
        );
      case PromptFailed(:final error, :final rejected):
        showFailure(context, error, onRetry: rejected ? null : _onEnterPressed);
      case PromptIdle() || PromptAsking():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isLoading = ref.watch(goalPromptControllerProvider) is PromptAsking;
    ref.listen(goalPromptControllerProvider, (_, next) => _onChanged(next));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createGoal)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.tellWhatYourGoalIs,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: AppType.headingHeight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.beDetailedOfYourGoal,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _promptField(l10n, isLoading: isLoading),
                const SizedBox(height: AppSpacing.md),
                _nextButton(l10n, isLoading: isLoading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The prompt itself: a roomy multi-line field with a 500-character budget.
  Widget _promptField(AppLocalizations l10n, {required bool isLoading}) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _promptController,
      focusNode: _promptFocusNode,
      enabled: !isLoading,
      decoration: InputDecoration(
        hintText: l10n.yourAnswer,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: AppStroke.thick,
          ),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      maxLength: 500,
      maxLines: 7,
      minLines: 5,
      style: theme.textTheme.bodyLarge?.copyWith(height: AppType.bodyHeight),
      onChanged: (value) => setState(() {}),
      textInputAction: TextInputAction.newline,
    );
  }

  /// Sends the prompt; a spinner takes the label while the call is in flight.
  Widget _nextButton(AppLocalizations l10n, {required bool isLoading}) {
    return SizedBox(
      width: double.infinity,
      child: LoadingButton(
        label: l10n.next,
        isLoading: isLoading,
        onPressed: isLoading ? null : _onEnterPressed,
      ),
    );
  }
}
