import 'package:flutter/material.dart';
import '../../../widgets/screens/goals/roadmap/follow_up_questions.dart';

class RoadmapQuestionsScreen extends StatefulWidget {
  final List<String> questions;

  const RoadmapQuestionsScreen({
    super.key,
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

  void _onSendPressed() {
    if (_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('roadmap layout soon!')),
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
        title: const Text('Questions'),
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
                child: const Text(
                  'Send',
                  style: TextStyle(
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