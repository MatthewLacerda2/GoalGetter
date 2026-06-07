import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/features/onboarding/debug/mock_study_plan.dart';
import 'package:goal_getter/features/onboarding/domain/study_plan.dart';

/// A simple confirmation screen: the goal's name, a short AI-generated summary
/// of what the user will study (markdown), and confirm / deny actions. Denying
/// sends the user back to the goal prompt to start over.
class StudyPlanScreen extends ConsumerStatefulWidget {
  final StudyPlan plan;

  const StudyPlanScreen({super.key, required this.plan});

  @override
  ConsumerState<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends ConsumerState<StudyPlanScreen> {
  late final _authService = ref.read(authServiceProvider);
  bool _isLoading = false;

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      await submitMockFullCreation(context, widget.plan, _authService);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _deny() => context.go(AppRoutes.goalPrompt);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
                        widget.plan.goalName,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _Description(markdown: widget.plan.description),
                    ],
                  ),
                ),
              ),
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

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
