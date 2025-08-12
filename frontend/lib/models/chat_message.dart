enum ChatMessageSender {
  user,
  tutor,
}

class ChatMessage {
  final String id;
  final String message;
  final ChatMessageSender sender;

  ChatMessage({
    required this.id,
    required this.message,
    required this.sender,
  });
}