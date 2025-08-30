import 'package:flutter/material.dart';
import 'package:goal_getter/l10n/app_localizations.dart';
import '../../../../models/question_data.dart';
import 'question_choices_list.dart';

class LessonQuestion extends StatefulWidget {
  final QuestionData questionData;
  final VoidCallback onQuestionAnswered;

  const LessonQuestion({
    super.key,
    required this.questionData,
    required this.onQuestionAnswered,
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

  void _continueToNext() {
    widget.onQuestionAnswered();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            widget.questionData.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 24),
          
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
          
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedIndex == null 
                    ? null 
                    : isAnswered 
                        ? _continueToNext
                        : _checkAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAnswered
                      ? (isCorrect ? Colors.green : Colors.red.withValues(alpha: 0.8))
                      : const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isAnswered
                      ? (isCorrect ? AppLocalizations.of(context)!.wellDone : AppLocalizations.of(context)!.opsNotQuite)
                      : AppLocalizations.of(context)!.enter,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
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

