import 'package:flutter/material.dart';
import 'goal_questions_screen.dart';
import '../../l10n/app_localizations.dart';
import 'package:openapi/api.dart';

class GoalPromptScreen extends StatefulWidget {
  const GoalPromptScreen({super.key});

  @override
  State<GoalPromptScreen> createState() => _GoalPromptScreenState();
}

class _GoalPromptScreenState extends State<GoalPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  
  final _promptFocusNode = FocusNode();

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
    final goalApi = OnboardingApi(ApiClient(basePath: 'http://127.0.0.1:8000'));//TODO: read from env
    final request = GoalCreationFollowUpQuestionsRequest(
      prompt: prompt
    );
    final response = await goalApi.generateFollowUpQuestionsApiV1OnboardingFollowUpQuestionsPost(request);
    return response?.questions;
  }

  void _onEnterPressed() async {
    if (_promptController.text.length >= 16) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final questions = await _fetchObjectiveQuestions(_promptController.text);
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
          )
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
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _promptController,
                focusNode: _promptFocusNode,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.goalDescriptionHintText,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[800],
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                maxLength: 500,
                maxLines: 8,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onEnterPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    AppLocalizations.of(context)!.enter,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}