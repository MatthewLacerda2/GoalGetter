import 'package:flutter/material.dart';

import 'package:goal_getter/features/tutor/presentation/chat_bubbles.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// One chat bubble. A tutor bubble likes its exchange on a double tap; the
/// reply's last bubble also shows the heart, which toggles the like on a tap.
/// A pending user bubble is faded; a failed one says why underneath.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.bubble, this.onToggleLike});

  final ChatBubbleData bubble;
  final VoidCallback? onToggleLike;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fromTutor = bubble.fromTutor;

    final body = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: fromTutor ? colors.surfaceContainerHigh : colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.bubble),
      ),
      child: Text(
        bubble.text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: fromTutor ? colors.onSurface : colors.onPrimary,
          height: 1.6,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxs,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: fromTutor
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: fromTutor
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: GestureDetector(
                  onDoubleTap: fromTutor ? onToggleLike : null,
                  child: Opacity(
                    opacity: bubble.status == BubbleStatus.sent ? 1 : 0.6,
                    child: body,
                  ),
                ),
              ),
              if (bubble.carriesHeart) _Heart(bubble.isLiked, onToggleLike),
            ],
          ),
          if (bubble.status == BubbleStatus.failed) _NotSent(bubble.error),
        ],
      ),
    );
  }
}

class _Heart extends StatelessWidget {
  const _Heart(this.isLiked, this.onTap);

  final bool isLiked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      tooltip: AppLocalizations.of(context).tutorLikeReply,
      icon: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? colors.error : colors.onSurfaceVariant,
      ),
    );
  }
}

class _NotSent extends StatelessWidget {
  const _NotSent(this.error);

  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.tutorNotSent(error ?? l10n.tutorUnreachable),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
