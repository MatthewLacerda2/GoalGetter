import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/openapi_client_factory.dart';
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.tellWhatYourGoalIs,
                style: const TextStyle(fontSize: 18, color: Colors.white),
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
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    tooltip: AppLocalizations.of(context)!.enter,
                    onPressed: _isLoading ? null : _onEnterPressed,
                  ),
                ),
                maxLength: 500,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
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
