import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/onboarding/data/onboarding_api.dart';
import 'package:goal_getter/features/onboarding/domain/goal_creation.dart';
import 'package:goal_getter/features/onboarding/presentation/controllers/pending_goal_draft.dart';
import 'package:goal_getter/features/onboarding/presentation/widgets/step_error.dart';

/// Step 3 of goal creation: the goal's name, a short AI-generated summary of
/// what the student will study (markdown), and confirm / start over.
///
/// Confirming sends `POST /goals`, which needs a session. Without one the
/// draft is held and the student goes to sign in; the sign-in brings them back
/// here (see `routeAfterSignIn`). On success the goal is stored as active and
/// its introduction screens play before home.
class StudyPlanScreen extends ConsumerStatefulWidget {
  final GoalDraft draft;

  const StudyPlanScreen({super.key, required this.draft});

  @override
  ConsumerState<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends ConsumerState<StudyPlanScreen> {
  bool _isLoading = false;
  Object? _error;

  Future<void> _confirm() async {
    ref.read(pendingGoalDraftProvider.notifier).hold(widget.draft);
    if (!ref.read(authServiceProvider).isSignedIn()) {
      context.go(AppRoutes.start);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final created = await ref
          .read(onboardingApiProvider)
          .create(widget.draft);
      await ref.read(settingsStorageProvider).writeCurrentGoalId(created.id);
      ref.read(pendingGoalDraftProvider.notifier).clear();
      if (mounted) context.go(AppRoutes.goalIntro, extra: created.introScreens);
    } on ApiException catch (e) {
      // A 401 the client could not refresh has already sent the student to
      // sign in; the held draft brings them back.
      if (mounted && e.status != 401) setState(() => _error = e);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _deny() {
    ref.read(pendingGoalDraftProvider.notifier).clear();
    context.go(AppRoutes.goalPrompt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = widget.draft.plan;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.studyPlan)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        plan.goalName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Description(markdown: plan.description),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                StepError(
                  error: _error!,
                  onRetry: _isLoading ? null : _confirm,
                ),
              ],
              const SizedBox(height: 20),
              _Actions(
                isLoading: _isLoading,
                onConfirm: _isLoading ? null : _confirm,
                onDeny: _isLoading ? null : _deny,
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
    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.6);

    return MarkdownBody(
      data: markdown,
      styleSheet: MarkdownStyleSheet(
        p: body,
        listBullet: body,
        strong: body?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        blockSpacing: 10.0,
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

    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: onDeny,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF5A623),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
            ),
            child: Text(
              l10n.startOver,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: onConfirm,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    l10n.startLearning,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
