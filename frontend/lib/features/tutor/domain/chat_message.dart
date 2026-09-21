//INFO: placeholder model. To be replaced by the hand-written API layer (core/api).
enum ChatMessageSender { user, tutor }

class ChatMessage {
  final String id;
  final String message;
  final ChatMessageSender sender;
  final bool isLiked;

  ChatMessage({
    required this.id,
    required this.message,
    required this.sender,
    this.isLiked = false,
  });
}
