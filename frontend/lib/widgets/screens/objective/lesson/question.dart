import 'package:flutter/material.dart';
import '../../../../models/question_data.dart';
import 'question_choice_list.dart';

class Question extends StatefulWidget {
  final QuestionData questionData;
  final Function(int)? onChoiceSelected;
  final VoidCallback? onAnswerRevealed;

  const Question({
    super.key,
    required this.questionData,
    this.onChoiceSelected,
    this.onAnswerRevealed,
  });

  @override
  State<Question> createState() => _QuestionState();
}

class _QuestionState extends State<Question> {
  int? selectedChoiceIndex;
  bool hasAnswered = false;
  bool? isCorrect;

  void _handleEnter() {
    if (selectedChoiceIndex == null || hasAnswered) return;
    
    setState(() {
      hasAnswered = true;
      isCorrect = widget.questionData.choices[selectedChoiceIndex!] == widget.questionData.correctAnswer;
    });
    
    // Notify parent that answer is revealed
    widget.onAnswerRevealed?.call();
  }

  Color _getButtonColor() {
    if (hasAnswered) {
      return isCorrect! ? Colors.green : Colors.red;
    }
    return selectedChoiceIndex != null ? Colors.blueGrey : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question text
        Text(
          widget.questionData.question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // Choice list
        QuestionChoiceList(
          choices: widget.questionData.choices,
          selectedIndex: selectedChoiceIndex,
          correctAnswer: widget.questionData.correctAnswer,
          hasAnswered: hasAnswered,
          onChoiceSelected: (index) {
            setState(() {
              selectedChoiceIndex = index;
            });
            widget.onChoiceSelected?.call(index);
          },
        ),
        const Spacer(),
        // Enter button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedChoiceIndex != null && !hasAnswered ? _handleEnter : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getButtonColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Enter',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}