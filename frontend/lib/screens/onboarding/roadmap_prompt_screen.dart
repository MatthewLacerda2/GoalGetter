import 'package:flutter/material.dart';
import 'roadmap_questions_screen.dart';
import '../../l10n/app_localizations.dart';
import 'package:openapi/api.dart';
//TODO: change 'roadmap' to 'objective'. use mock again for now
class RoadmapPromptScreen extends StatefulWidget {
  const RoadmapPromptScreen({super.key});

  @override
  State<RoadmapPromptScreen> createState() => _RoadmapPromptScreenState();
}

class _RoadmapPromptScreenState extends State<RoadmapPromptScreen> {
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

  Future<List<String>?> _fetchRoadmapQuestions(String prompt) async {
    final roadmapApi = RoadmapApi(ApiClient(basePath: 'http://127.0.0.1:8000'));//TODO: read from env
    final request = RoadmapInitiationRequest(
      promptHint: AppLocalizations.of(context)!.tellWhatYourGoalIs, 
      prompt: prompt
    );
    final response = await roadmapApi.initiateRoadmapApiV1RoadmapInitiationPost(request);
    return response?.questions;
  }

  void _onEnterPressed() async {
    if (_promptController.text.length >= 16) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final questions = await _fetchRoadmapQuestions(_promptController.text);
        if (mounted) {
          if (questions != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoadmapQuestionsScreen(
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
        title: Text(AppLocalizations.of(context)!.createRoadmap),
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