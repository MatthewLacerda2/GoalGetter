import 'package:flutter/material.dart';
import 'question_choice.dart';

class QuestionChoicesList extends StatefulWidget {
  final List<String> choices;
  final int correctAnswerIndex;
  final Function(int)? onChoiceSelected;
  final bool isAnswered;
  final bool isCorrect;

  const QuestionChoicesList({
    super.key,
    required this.choices,
    required this.correctAnswerIndex,
    this.onChoiceSelected,
    this.isAnswered = false,
    this.isCorrect = false,
  });

  @override
  State<QuestionChoicesList> createState() => _QuestionChoicesListState();
}

class _QuestionChoicesListState extends State<QuestionChoicesList> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < widget.choices.length; i++) ...[
          QuestionChoice(
            text: widget.choices[i],
            borderColor: widget.isAnswered
                ? (i == widget.correctAnswerIndex 
                    ? Colors.green 
                    : (selectedIndex == i ? Colors.red : Colors.grey))
                : (selectedIndex == i ? Colors.blue : Colors.grey),
            backgroundColor: widget.isAnswered
                ? (i == widget.correctAnswerIndex 
                    ? Colors.green.withValues(alpha: 0.13)
                    : (selectedIndex == i 
                        ? Colors.red.withValues(alpha: 0.13)
                        : Colors.transparent)) 
                : (selectedIndex == i 
                    ? Colors.white.withValues(alpha: 0.13)
                    : Colors.transparent), 
            onTap: () {
              if (!widget.isAnswered) {
                setState(() {
                  selectedIndex = selectedIndex == i ? null : i;
                });
                widget.onChoiceSelected?.call(selectedIndex ?? -1);
              }
            },
          ),
          if (i < widget.choices.length - 1) const SizedBox(height: 16),
        ],
      ],
    );
  }
}