/// One exchange with the tutor (`chat_exchange` in the API): the student's
/// prompt and the tutor's reply, which Gemini writes as several short strings
/// that the chat shows as one bubble each.
class ChatExchange {
  const ChatExchange({
    required this.id,
    required this.prompt,
    required this.responses,
    required this.isLiked,
    required this.createdAt,
  });

  factory ChatExchange.fromJson(Map<String, dynamic> json) => ChatExchange(
    id: json['id'] as String,
    prompt: json['prompt'] as String,
    responses: (json['responses'] as List).cast<String>(),
    isLiked: json['is_liked'] as bool,
    createdAt: json['created_at'] as String,
  );

  final String id;
  final String prompt;
  final List<String> responses;
  final bool isLiked;

  /// Kept as the server's string, not a DateTime: it is the `before` cursor
  /// of the next page, and a web DateTime drops the microseconds, which would
  /// move the cursor.
  final String createdAt;

  ChatExchange copyWith({bool? isLiked}) => ChatExchange(
    id: id,
    prompt: prompt,
    responses: responses,
    isLiked: isLiked ?? this.isLiked,
    createdAt: createdAt,
  );
}
