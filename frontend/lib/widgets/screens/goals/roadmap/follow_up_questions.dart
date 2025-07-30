import 'package:flutter/material.dart';

class FollowUpQuestions extends StatefulWidget {
  final List<String> questions;
  final Function(List<String> answers)? onAnswersComplete;
  final bool showErrors; // NEW

  const FollowUpQuestions({
    super.key,
    required this.questions,
    this.onAnswersComplete,
    this.showErrors = false, // NEW
  });

  @override
  State<FollowUpQuestions> createState() => _FollowUpQuestionsState();
}

class _FollowUpQuestionsState extends State<FollowUpQuestions> {
  final List<TextEditingController> _controllers = [];
  final List<String> _answers = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers and answers for each question
    for (int i = 0; i < widget.questions.length; i++) {
      _controllers.add(TextEditingController());
      _answers.add('');
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onAnswerChanged(int index, String value) {
    setState(() {
      _answers[index] = value;
    });
    
    // Call callback if all questions are answered
    if (widget.onAnswersComplete != null && 
        _answers.every((answer) => answer.trim().isNotEmpty)) {
      widget.onAnswersComplete!(_answers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.questions.length,
      itemBuilder: (context, index) {
        final isEmpty = _answers[index].trim().isEmpty;
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question text
              Text(
                widget.questions[index],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              // Answer input field
              TextField(
                controller: _controllers[index],
                onChanged: (value) => _onAnswerChanged(index, value),
                decoration: InputDecoration(
                  hintText: 'Your answer...',
                  border: UnderlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  // NEW: error styling
                  errorText: widget.showErrors && isEmpty ? 'Please answer this question' : null,
                ),
                maxLines: 5,
                minLines: 1,
                textInputAction: index < widget.questions.length - 1 
                    ? TextInputAction.next 
                    : TextInputAction.done,
              ),
            ],
          ),
        );
      },
    );
  }
}