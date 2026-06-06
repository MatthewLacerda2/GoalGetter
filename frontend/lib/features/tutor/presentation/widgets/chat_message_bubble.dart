import 'package:flutter/material.dart';

import 'package:goal_getter/features/tutor/domain/chat_message.dart';
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDoubleTap;

  ChatMessageBubble({super.key, required this.message, this.onDoubleTap});

  @override
  Widget build(BuildContext context) {
    final isTutor = message.sender == ChatMessageSender.tutor;

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: 4.0,
        horizontal: 12.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isTutor
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onDoubleTap: onDoubleTap,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: isTutor
                      ? Theme.of(context).colorScheme.surfaceContainerHigh
                      : Theme.of(context).colorScheme.primary,
                  borderRadius:
                      BorderRadius.circular(24.0),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: message.isLiked ? 18.0 : 0.0,
                      ),
                      child: Text(
                        message.message,
                        style: TextStyle(
                          fontSize: 16.0,
                          color: isTutor
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.white,
                          height: 1.6,
                        ),
                      ),
                    ),
                    if (message.isLiked)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(
                          Icons.favorite,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
