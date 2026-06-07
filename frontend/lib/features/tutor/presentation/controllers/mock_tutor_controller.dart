import 'package:goal_getter/features/tutor/domain/chat_message.dart';

/// Returns a simulated history of chat messages with the AI tutor.
///
/// Demo user: learning Italian, 7 days in. See docs/backend_contract.md
/// (GET /tutor/messages).
Future<List<ChatMessage>> getMockChatMessages() async {
  await Future.delayed(const Duration(milliseconds: 800));
  return [
    ChatMessage(
      id: "msg_1",
      message: "Ciao Marco! 👋 Great work keeping your 7-day streak. Want to review what tripped you up yesterday, or start something new?",
      sender: ChatMessageSender.tutor,
    ),
    ChatMessage(
      id: "msg_2",
      message: "I keep mixing up 'essere' and 'avere'. When do I use each?",
      sender: ChatMessageSender.user,
    ),
    ChatMessage(
      id: "msg_3",
      message:
          "Good one — that's the classic Italian hurdle.\n\n• 'essere' (to be) → identity, states, location: \"Sono stanco\" (I am tired).\n• 'avere' (to have) → possession, age, and many idioms: \"Ho 30 anni\" (I'm 30 — literally 'I have 30 years').\n\nItalians say \"ho fame\" (I have hunger), not \"sono fame\".",
      sender: ChatMessageSender.tutor,
      isLiked: true,
    ),
    ChatMessage(
      id: "msg_4",
      message: "Ahh that makes sense. So 'ho sete' = I'm thirsty?",
      sender: ChatMessageSender.user,
    ),
    ChatMessage(
      id: "msg_5",
      message: "Esatto! 🎯 Perfect. Ready for a quick 5-question lesson on essere vs avere to lock it in?",
      sender: ChatMessageSender.tutor,
    ),
  ];
}

/// Generates a mock AI tutor reply after a brief thinking delay.
Future<ChatMessage> getMockTutorResponse(String userMessage) async {
  await Future.delayed(const Duration(milliseconds: 1500));
  return ChatMessage(
    id: "msg_reply_${DateTime.now().millisecondsSinceEpoch}",
    message:
        "Ottima domanda! Let's work through \"$userMessage\" together. "
        "I'll tie it back to what you practiced this week so it sticks — "
        "want an example sentence to try?",
    sender: ChatMessageSender.tutor,
  );
}
