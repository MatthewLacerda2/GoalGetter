import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class GoalQuestions extends StatefulWidget {
  final String question;
  final String? initialAnswer;
  final Function(String answer) onAnswerSubmitted;
  final bool isActive;
  final bool showError;
  final TextEditingController? controller;

  const GoalQuestions({
    super.key,
    required this.question,
    this.initialAnswer,
    required this.onAnswerSubmitted,
    this.isActive = true,
    this.showError = false,
    this.controller,
  });

  @override
  State<GoalQuestions> createState() => _GoalQuestionsState();
}

class _GoalQuestionsState extends State<GoalQuestions> {
  late TextEditingController _textController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _textController = widget.controller ?? TextEditingController();
    if (widget.initialAnswer != null) {
      _textController.text = widget.initialAnswer!;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _textController.dispose();
    }
    super.dispose();
  }

  void _handleSubmitted(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      setState(() {
        _hasError = true;
      });
      return;
    }

    setState(() {
      _hasError = false;
    });

    widget.onAnswerSubmitted(trimmedValue);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Text(
            widget.question,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Answer input field
          TextField(
            controller: _textController,
            enabled: widget.isActive,
            onSubmitted: _handleSubmitted,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.yourAnswer,
              border: const UnderlineInputBorder(),
              filled: true,
              fillColor: widget.isActive 
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              errorText: (widget.showError || _hasError) && _textController.text.trim().isEmpty
                  ? AppLocalizations.of(context)!.pleaseAnswerThisQuestion
                  : null,
              suffixIcon: widget.isActive
                  ? IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _handleSubmitted(_textController.text),
                      tooltip: 'Submit',
                    )
                  : null,
            ),
            maxLines: 5,
            minLines: 3,
            textInputAction: TextInputAction.send,
            onChanged: (value) {
              if (_hasError && value.trim().isNotEmpty) {
                setState(() {
                  _hasError = false;
                });
              }
            },
          ),
        ],
      ),
    );
  }
}