// lesson screen
import 'package:flutter/material.dart';
import '../../../../widgets/tutor/chat_message_bubble.dart';
import '../../../../models/chat_message.dart';
import '../../../../widgets/tutor/chat_input.dart';

class LessonScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  
  const LessonScreen({
    super.key,
    required this.messages,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  int _messageId = 0;

  @override
  void initState() {
    super.initState();
    _messages.addAll(widget.messages);
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          id: (_messageId++).toString(),
          message: _textController.text.trim(),
          sender: ChatMessageSender.user,
        ));
      });
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatMessageBubble(message: message);
              },
            ),
          ),
          ChatInput(
            controller: _textController,
            onSendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

