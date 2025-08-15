import 'package:flutter/material.dart';
import '../widgets/tutor/chat_message_bubble.dart';
import '../models/chat_message.dart';
import '../widgets/tutor/chat_input.dart';

class TutorScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  
  const TutorScreen({
    super.key,
    required this.messages,
  });

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  int _messageId = 0;

  @override
  void initState() {
    super.initState();
    _messages.addAll(widget.messages);
    // Scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 8),
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
    _scrollController.dispose();
    super.dispose();
  }
}

