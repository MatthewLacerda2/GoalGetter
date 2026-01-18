import 'package:flutter/material.dart';

import '../../models/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDoubleTap;

  const ChatMessageBubble({super.key, required this.message, this.onDoubleTap});

  @override
  Widget build(BuildContext context) {
    final isTutor = message.sender == ChatMessageSender.tutor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isTutor ? Colors.grey[800] : Colors.grey[700],
                  borderRadius: BorderRadius.circular(16),
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
                          fontSize: 16,
                          color: Colors.white,
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
                          color: Colors.red[400],
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
