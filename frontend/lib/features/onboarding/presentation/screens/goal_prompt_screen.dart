import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/app/router/route_args.dart';
import 'package:goal_getter/core/services/auth_service.dart';
import 'package:goal_getter/features/onboarding/debug/mock_goal_prompt_screen.dart';

class GoalPromptScreen extends ConsumerStatefulWidget {
  const GoalPromptScreen({super.key});

  @override
  ConsumerState<GoalPromptScreen> createState() => _GoalPromptScreenState();
}

class _GoalPromptScreenState extends ConsumerState<GoalPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();

  final _promptFocusNode = FocusNode();
  late final _authService = ref.read(authServiceProvider);

  bool _isLoading = false;

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

  Future<List<MockMultipleChoiceQuestion>> _fetchObjectiveQuestions(String prompt) async {
    return await fetchMockObjectiveQuestions(context, prompt);
  }

  void _onEnterPressed() async {
    if (_promptController.text.length >= 16) {
      setState(() {
        _isLoading = true;
      });

      try {
        final questions = await _fetchObjectiveQuestions(
          _promptController.text,
        );
        if (mounted) {
          context.push(
            AppRoutes.goalQuestions,
            extra: GoalQuestionsArgs(
              prompt: _promptController.text,
              questions: questions,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.beDetailedOfYourGoal),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createGoal)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
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
                TextFormField(
                  controller: _promptController,
                  focusNode: _promptFocusNode,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: l10n.yourAnswer,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHigh,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide:
                          BorderSide(color: theme.colorScheme.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(18.0),
                  ),
                  maxLength: 500,
                  maxLines: 7,
                  minLines: 5,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  onChanged: (value) => setState(() {}),
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _onEnterPressed,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            l10n.next,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
