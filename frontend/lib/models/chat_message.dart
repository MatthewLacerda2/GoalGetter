//INFO: this is just a placeholder model. Once we get the client_sdk, this'll be deleted
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