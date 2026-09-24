import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/tutor/presentation/chat_bubbles.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_state.dart';

import 'fake_tutor_api.dart';

void main() {
  test('an exchange is one user bubble plus one tutor bubble per response', () {
    final bubbles = chatBubbles([exchange(1, liked: true)], null);
    // Newest first: the reply's last bubble is at the bottom of the chat.
    expect(
      [for (final b in bubbles) b.text],
      ['reply 1.b', 'reply 1.a', 'prompt 1'],
    );
    expect([for (final b in bubbles) b.fromTutor], [true, true, false]);
    expect([for (final b in bubbles) b.carriesHeart], [true, false, false]);
    expect(bubbles.first.isLiked, isTrue);
    expect(bubbles.first.exchangeId, 'e1');
  });

  test('the pending message is the newest bubble, with its status', () {
    final bubbles = chatBubbles([
      exchange(1),
    ], const PendingSend('ciao', failed: true));
    expect(bubbles.first.text, 'ciao');
    expect(bubbles.first.status, BubbleStatus.failed);
  });
}
