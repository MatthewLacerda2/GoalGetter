import 'package:flutter/material.dart';
import 'question_choice.dart';

class QuestionChoiceList extends StatelessWidget {
  final List<String> choices;
  final int? selectedIndex;
  final String correctAnswer;
  final bool hasAnswered;
  final Function(int)? onChoiceSelected;

  const QuestionChoiceList({
    super.key,
    required this.choices,
    this.selectedIndex,
    required this.correctAnswer,
    this.hasAnswered = false,
    this.onChoiceSelected,
  });

  Color _getChoiceColor(int index) {
    if (!hasAnswered) {
      return selectedIndex == index ? Colors.blue : Colors.blueGrey;
    }
    
    // After answering, show correct/incorrect colors
    final isSelected = selectedIndex == index;
    final isCorrect = choices[index] == correctAnswer;
    
    if (isCorrect) {
      return Colors.green;
    } else if (isSelected) {
      return Colors.red;
    } else {
      return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: choices.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: QuestionChoice(
            text: choices[index],
            borderColor: _getChoiceColor(index),
            backgroundColor: Colors.transparent,
            onTap: hasAnswered ? null : () => onChoiceSelected?.call(index),
          ),
        );
      },
    );
  }
}