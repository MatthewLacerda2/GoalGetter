import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import '../../services/auth_service.dart';
import '../../services/openapi_client_factory.dart';
import 'goal_questions_screen.dart';
import 'mock_goal_prompt_screen.dart';

class GoalPromptScreen extends StatefulWidget {
  GoalPromptScreen({super.key});

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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GoalQuestionsScreen(
                prompt: _promptController.text,
                questions: questions,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: $e',
                style: TextStyle(color: Colors.black),
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
            style: TextStyle(color: Colors.black),
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
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.tellWhatYourGoalIs,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _promptController,
                focusNode: _promptFocusNode,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
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
