import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_state.dart';

enum BubbleStatus { sent, sending, failed }

/// One bubble on screen. An exchange becomes one user bubble plus one tutor
/// bubble per response; the reply's last bubble carries the exchange's heart.
class ChatBubbleData {
  const ChatBubbleData({
    required this.text,
    required this.fromTutor,
    this.exchangeId,
    this.carriesHeart = false,
    this.isLiked = false,
    this.status = BubbleStatus.sent,
  });

  final String text;
  final bool fromTutor;

  /// The exchange a tutor bubble belongs to; a double tap likes it.
  final String? exchangeId;
  final bool carriesHeart;
  final bool isLiked;
  final BubbleStatus status;
}

/// Newest first, the order a reversed ListView draws from the bottom up.
List<ChatBubbleData> chatBubbles(
  List<ChatExchange> exchanges,
  PendingSend? pending,
) {
  final bubbles = <ChatBubbleData>[
    if (pending != null)
      ChatBubbleData(
        text: pending.text,
        fromTutor: false,
        status: pending.failed ? BubbleStatus.failed : BubbleStatus.sending,
      ),
  ];
  for (final exchange in exchanges.reversed) {
    final replies = exchange.responses;
    for (var i = replies.length - 1; i >= 0; i--) {
      bubbles.add(
        ChatBubbleData(
          text: replies[i],
          fromTutor: true,
          exchangeId: exchange.id,
          carriesHeart: i == replies.length - 1,
          isLiked: exchange.isLiked,
        ),
      );
    }
    bubbles.add(ChatBubbleData(text: exchange.prompt, fromTutor: false));
  }
  return bubbles;
}
