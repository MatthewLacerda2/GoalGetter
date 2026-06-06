import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendMessage;
  final bool isSending;

  ChatInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.0),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16.0,
              ),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.typeYourMessage,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSendMessage(),
            ),
          ),
          IconButton(
            onPressed: isSending ? null : onSendMessage,
            icon: isSending
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Icon(Icons.send),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}