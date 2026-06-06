import '../models/chat_message.dart';

/// Returns a simulated history of chat messages with the AI tutor.
Future<List<ChatMessage>> getMockChatMessages() async {
  await Future.delayed(const Duration(milliseconds: 800));
  return [
    ChatMessage(
      id: "msg_1",
      message: "Hello! I am your AI Tutor. What would you like to review today?",
      sender: ChatMessageSender.tutor,
    ),
    ChatMessage(
      id: "msg_2",
      message: "I am working on my goal and want to understand how components state works.",
      sender: ChatMessageSender.user,
    ),
    ChatMessage(
      id: "msg_3",
      message: "State represents the configuration of a component at a given moment. In Flutter, we use state management like Riverpod to update the UI dynamically. Shall we run a quick exercise?",
      sender: ChatMessageSender.tutor,
    ),
  ];
}

/// Generates a mock AI tutor reply after a brief thinking delay.
Future<ChatMessage> getMockTutorResponse(String userMessage) async {
  await Future.delayed(const Duration(milliseconds: 1500));
  return ChatMessage(
    id: "msg_reply_${DateTime.now().millisecondsSinceEpoch}",
    message: "That's a great question about '$userMessage'. When building mobile apps, separating your presentation layers from your business logic is key. Let's dig deeper into this in our next lesson!",
    sender: ChatMessageSender.tutor,
  );
}
