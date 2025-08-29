import 'package:flutter/material.dart';
import '../../../../models/question_data.dart';
import 'question_choices_list.dart';

class LessonQuestion extends StatefulWidget {
  final QuestionData questionData;

  const LessonQuestion({
    super.key,
    required this.questionData,
  });

  @override
  State<LessonQuestion> createState() => _LessonQuestionState();
}

class _LessonQuestionState extends State<LessonQuestion> {
  int? selectedIndex;
  bool isAnswered = false;
  bool isCorrect = false;

  void _checkAnswer() {
    if (selectedIndex == null) return;
    
    setState(() {
      isAnswered = true;
      isCorrect = selectedIndex == widget.questionData.correctAnswerIndex;
      widget.questionData.status = isCorrect 
          ? QuestionStatus.correct 
          : QuestionStatus.incorrect;
    });
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
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Question choices
        QuestionChoicesList(
          choices: widget.questionData.choices,
          correctAnswerIndex: widget.questionData.correctAnswerIndex,
          onChoiceSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          isAnswered: isAnswered,
          isCorrect: isCorrect,
        ),
        
        const Spacer(),
        
        // Enter button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedIndex == null || isAnswered ? null : _checkAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAnswered
                  ? (isCorrect ? Colors.green : Colors.red)
                  : const Color(0xFF2E7D32), // Dark green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isAnswered
                  ? (isCorrect ? 'Right' : 'Wrong')
                  : 'Enter',
              style: const TextStyle(
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

