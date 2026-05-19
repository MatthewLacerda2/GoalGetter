import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/openapi_client_factory.dart';
import '../../theme/app_theme.dart';
import 'goal_questions_screen.dart';

class GoalPromptScreen extends StatefulWidget {
  const GoalPromptScreen({super.key});

  @override
  State<GoalPromptScreen> createState() => _GoalPromptScreenState();
}

class _GoalPromptScreenState extends State<GoalPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();

  final _promptFocusNode = FocusNode();
  final _authService = AuthService();

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

  Future<List<String>?> _fetchObjectiveQuestions(String prompt) async {
    final apiClient = await OpenApiClientFactory(
      authService: _authService,
    ).createWithGoogleToken();

    final goalApi = OnboardingApi(apiClient);
    final request = GoalCreationFollowUpQuestionsRequest(prompt: prompt);
    final response = await goalApi
        .generateFollowUpQuestionsApiV1OnboardingFollowUpQuestionsPost(request);
    return response?.questions;
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
          if (questions != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoalQuestionsScreen(
                  prompt: _promptController.text,
                  questions: questions,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error: No questions received',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.black),
              ),
            ),
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
          content: Text(
            AppLocalizations.of(context)!.beDetailedOfYourGoal,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createGoal),
        backgroundColor: Colors.grey[800],
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.edgePadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.tellWhatYourGoalIs,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _promptController,
                focusNode: _promptFocusNode,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[800],
                  hintStyle: Theme.of(context).textTheme.bodySmall,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    tooltip: AppLocalizations.of(context)!.enter,
                    onPressed: _isLoading ? null : _onEnterPressed,
                  ),
                ),
                maxLength: 500,
                maxLines: 8,
                style: Theme.of(context).textTheme.bodyLarge,
                onChanged: (value) => setState(() {}),
                textInputAction: TextInputAction.send,
                onFieldSubmitted: (_) => _onEnterPressed(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
