import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import '../../../widgets/screens/goals/roadmap/follow_up_questions.dart';
import 'roadmap_lay_out_screen.dart';
import '../../../l10n/app_localizations.dart';

class RoadmapQuestionsScreen extends StatefulWidget {
  final List<String> questions;
  final String prompt;

  const RoadmapQuestionsScreen({
    super.key,
    required this.prompt,
    required this.questions,
  });

  @override
  State<RoadmapQuestionsScreen> createState() => _RoadmapQuestionsScreenState();
}

class _RoadmapQuestionsScreenState extends State<RoadmapQuestionsScreen> {
  List<String> _answers = [];
  bool _showErrors = false;

  void _onAnswersChanged(List<String> answers) {
    setState(() {
      _answers = answers;
      // Optionally reset errors if all are answered
      if (_allAnswered) _showErrors = false;
    });
  }

  bool get _allAnswered =>
      _answers.length == widget.questions.length &&
      _answers.every((a) => a.trim().isNotEmpty);

  Future<RoadmapCreationResponse?> _fetchRoadmapSteps(String prompt) async {
    List<FollowUpQuestionsAndAnswers> questionsAnswers = [];
    for (int i = 0; i < _answers.length; i++) {
      questionsAnswers.add(FollowUpQuestionsAndAnswers(question: widget.questions[i], answer: _answers[i]));
    }

    final roadmapApi = RoadmapApi(ApiClient(basePath: 'http://127.0.0.1:8000'));//TODO: read from env
    final request = RoadmapCreationRequest(
      prompt: prompt,
      questionsAnswers: questionsAnswers,
    );
    final response = await roadmapApi.createRoadmapApiV1RoadmapCreationPost(request);
    return response;
  }

  void _onSendPressed() async {
    if (_allAnswered) {
      final results = await _fetchRoadmapSteps(widget.prompt);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoadmapLayOutScreen(
            roadmapCreationResponse: results!,
          ),
        ),
      );
    } else {
      setState(() {
        _showErrors = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.questions),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: FollowUpQuestions(
              questions: widget.questions,
              onAnswersComplete: _onAnswersChanged,
              showErrors: _showErrors,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSendPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
                child: Text(
                  AppLocalizations.of(context)!.send,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}