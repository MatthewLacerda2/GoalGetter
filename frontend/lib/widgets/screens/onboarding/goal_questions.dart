import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
class GoalQuestions extends StatefulWidget {
  final String question;
  final String? initialAnswer;
  final Function(String answer) onAnswerSubmitted;
  final bool isActive;
  final bool showError;
  final TextEditingController? controller;

  GoalQuestions({
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
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12.0),
            TextField(
              controller: _textController,
              enabled: widget.isActive,
              onSubmitted: _handleSubmitted,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.yourAnswer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                filled: true,
                fillColor: widget.isActive
                    ? Theme.of(context).colorScheme.surfaceContainer
                    : Theme.of(context).colorScheme.surfaceContainerHigh,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                errorText: (widget.showError || _hasError) &&
                        _textController.text.trim().isEmpty
                    ? AppLocalizations.of(context)!.pleaseAnswerThisQuestion
                    : null,
                suffixIcon: widget.isActive
                    ? IconButton(
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () =>
                            _handleSubmitted(_textController.text),
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
      ),
    );
  }
}