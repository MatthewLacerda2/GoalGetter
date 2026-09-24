import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/step_error.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// Step 1 of goal creation: what the student wants to learn. Sends it to
/// `POST /goals/objective-questions`; a 400 there is Gemini saying it is not a
/// goal, and its reasoning is shown here so the student can rephrase.
class GoalPromptScreen extends ConsumerStatefulWidget {
  const GoalPromptScreen({super.key});

  @override
  ConsumerState<GoalPromptScreen> createState() => _GoalPromptScreenState();
}

class _GoalPromptScreenState extends ConsumerState<GoalPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();

  final _promptFocusNode = FocusNode();

  bool _isLoading = false;
  Object? _error;

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

  Future<void> _onEnterPressed() async {
    final prompt = _promptController.text.trim();
    if (prompt.length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).beDetailedOfYourGoal),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final questions = await ref
          .read(onboardingApiProvider)
          .objectiveQuestions(prompt);
      if (mounted) {
        context.push(
          AppRoutes.goalQuestions,
          extra: GoalQuestionsArgs(prompt: prompt, questions: questions),
        );
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// A rejected prompt wants rephrasing, not the same request again.
  bool get _isRejection =>
      _error is ApiException && (_error as ApiException).status == 400;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
                const SizedBox(height: 8),
                Text(
                  l10n.tellWhatYourGoalIs,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.beDetailedOfYourGoal,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _promptField(l10n),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  StepError(
                    error: _error!,
                    onRetry: _isRejection || _isLoading
                        ? null
                        : _onEnterPressed,
                  ),
                ],
                const SizedBox(height: 16),
                _nextButton(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The prompt itself: a roomy multi-line field with a 500-character budget.
  Widget _promptField(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: _promptController,
      focusNode: _promptFocusNode,
      enabled: !_isLoading,
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
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      maxLength: 500,
      maxLines: 7,
      minLines: 5,
      style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
      onChanged: (value) => setState(() {}),
      textInputAction: TextInputAction.newline,
    );
  }

  /// Sends the prompt; a spinner takes the label while the call is in flight.
  Widget _nextButton(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isLoading ? null : _onEnterPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(scheme.onPrimary),
                ),
              )
            : Text(
                l10n.next,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
