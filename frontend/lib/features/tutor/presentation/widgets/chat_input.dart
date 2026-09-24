import 'package:flutter/material.dart';

import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';
import 'package:goal_getter/app/theme/app_theme.dart';

/// The composer at the bottom of the tutor chat: a rounded field and the send
/// button, which turns into a spinner while a message is in flight.
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
      padding: EdgeInsets.all(AppSpacing.sm),
      color: AppTheme.transparent,
      child: Row(
        children: [
          Expanded(
            child: _MessageField(
              controller: controller,
              onSubmitted: onSendMessage,
            ),
          ),
          _SendButton(isSending: isSending, onSendMessage: onSendMessage),
        ],
      ),
    );
  }
}

/// The text field itself: rounded to [AppRadius.bubble], like the bubbles.
class _MessageField extends StatelessWidget {
  const _MessageField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).typeYourMessage,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.bubble),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.bubble),
          borderSide: BorderSide(
            color: scheme.outline.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.bubble),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      minLines: 1,
      maxLines: 4,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

/// Send, or the spinner that replaces it while the message is in flight.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.isSending, required this.onSendMessage});

  final bool isSending;
  final VoidCallback onSendMessage;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IconButton(
      onPressed: isSending ? null : onSendMessage,
      icon: isSending
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary),
            )
          : Icon(Icons.send),
      color: primary,
    );
  }
}