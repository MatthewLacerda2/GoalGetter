import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';

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
      color: AppTheme.surfaceVariant,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing24,
          vertical: AppTheme.spacing16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question,
              style: const TextStyle(
                fontSize: AppTheme.fontSize18,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing12),
            TextField(
              controller: _textController,
              enabled: widget.isActive,
              onSubmitted: _handleSubmitted,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.yourAnswer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: widget.isActive
                    ? AppTheme.cardBackground
                    : AppTheme.surfaceVariant,
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing12,
                ),
                errorText: (widget.showError || _hasError) &&
                        _textController.text.trim().isEmpty
                    ? AppLocalizations.of(context)!.pleaseAnswerThisQuestion
                    : null,
                suffixIcon: widget.isActive
                    ? IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: AppTheme.textPrimary,
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