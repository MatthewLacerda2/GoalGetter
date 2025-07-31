import 'package:flutter/material.dart';
import 'roadmap_questions_screen.dart';
import '../../../l10n/app_localizations.dart';
import 'package:openapi/api.dart';

//TODO: give visual feedback when the user hits 'send'
//TODO: snackbar for errors

const followUpQuestions = [
    "Why you decided to learn it?",
    "Why that instrument?",
    "What songs you wanna play?",
    "What do you wanna play it for?",
    "Do you know other instrument?",
];

class RoadmapPromptScreen extends StatefulWidget {
  const RoadmapPromptScreen({super.key});

  @override
  State<RoadmapPromptScreen> createState() => _RoadmapPromptScreenState();
}

class _RoadmapPromptScreenState extends State<RoadmapPromptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  
  // Focus nodes to track when fields are focused
  final _promptFocusNode = FocusNode();

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

  Future<List<String>?> _fetchRoadmapQuestions(String prompt) async {
    final roadmapApi = RoadmapApi(ApiClient(basePath: 'http://127.0.0.1:8000'));
    final request = RoadmapInitiationRequest(
      promptHint: AppLocalizations.of(context)!.tellWhatYourGoalIs, 
      prompt: prompt
    );
    final response = await roadmapApi.initiateRoadmapApiV1RoadmapInitiationPost(request);
    return response?.questions;
  }

  void _onEnterPressed() async {
    if (_promptController.text.length >= 16) {
      final questions = await _fetchRoadmapQuestions(_promptController.text);
      if (questions != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoadmapQuestionsScreen(
              questions: questions,
            ),
          ),
        );
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createRoadmap),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              // Main question
              //Text('State your problem. State your purpose. State your level.',
              Text(
                AppLocalizations.of(context)!.tellWhatYourGoalIs,
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _promptController,
                focusNode: _promptFocusNode,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.goalDescriptionHintText,
                  border: const OutlineInputBorder(),
                ),
                maxLength: 500,
                maxLines: 10,
                onChanged: (value) => setState(() {}),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _onEnterPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
            child: Text(
              AppLocalizations.of(context)!.enter,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}