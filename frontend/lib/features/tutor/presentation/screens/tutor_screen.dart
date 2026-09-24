import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/core/widgets/state_message.dart';
import 'package:goal_getter/features/tutor/presentation/chat_bubbles.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_controller.dart';
import 'package:goal_getter/features/tutor/presentation/widgets/chat_input.dart';
import 'package:goal_getter/features/tutor/presentation/widgets/chat_message_bubble.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/app/theme/app_dimens.dart';

/// The chat with the tutor, on the active goal. The list is reversed: the
/// newest bubble sits at the bottom, and scrolling up to the top loads older
/// exchanges without the view jumping.
class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  TutorController get _controller => ref.read(tutorControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadOlderNearTop);
  }

  /// Also runs after each change of the list, so a first page too short to
  /// scroll still reaches the older ones.
  void _loadOlderNearTop() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 200) _controller.loadOlder();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty || ref.read(tutorControllerProvider).isSending) {
      return;
    }
    _textController.clear();
    final failure = await _controller.send(text);
    if (failure == null || !mounted) return;
    // Give the text back so the student can send it again, unless they have
    // already started typing something else.
    if (_textController.text.isEmpty) _textController.text = text.trim();
    // The composer is at the bottom: the snackbar goes above it, not over it.
    showFailure(
      context,
      failure,
      onRetry: _send,
      position: FailurePosition.top,
    );
  }

  Future<void> _toggleLike(String exchangeId, bool isLiked) async {
    final failure = await _controller.setLike(exchangeId, !isLiked);
    if (failure == null || !mounted) return;
    showFailure(
      context,
      failure,
      title: AppLocalizations.of(context).tutorLikeFailed,
      onRetry: () => _toggleLike(exchangeId, isLiked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorControllerProvider);
    ref.listen(tutorControllerProvider, (previous, next) {
      if (previous?.exchanges.length != next.exchanges.length) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _loadOlderNearTop(),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: switch (state.load) {
        TutorLoad.loading => const Center(child: CircularProgressIndicator()),
        TutorLoad.noActiveGoal => const _NoActiveGoal(),
        TutorLoad.failed => FailureView(
          error: state.loadFailure,
          title: AppLocalizations.of(context).tutorLoadFailed,
          onRetry: _controller.load,
        ),
        TutorLoad.ready => Column(
          children: [
            Expanded(child: _chat(state)),
            ChatInput(
              controller: _textController,
              onSendMessage: _send,
              isSending: state.isSending,
            ),
          ],
        ),
      },
    );
  }

  Widget _chat(TutorState state) {
    final bubbles = chatBubbles(state.exchanges, state.pending);
    if (bubbles.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).tutorEmptyChat,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final showTop = state.isLoadingMore || state.loadMoreFailed;
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
      itemCount: bubbles.length + (showTop ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == bubbles.length) return _OlderStatus(state);
        final bubble = bubbles[index];
        final id = bubble.exchangeId;
        return ChatMessageBubble(
          bubble: bubble,
          onToggleLike: id == null
              ? null
              : () => _toggleLike(id, bubble.isLiked),
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

/// The row above the oldest bubble: a spinner, or the retry of a failed page.
class _OlderStatus extends ConsumerWidget {
  const _OlderStatus(this.state);

  final TutorState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return FailureView(
      error: state.loadMoreFailure,
      title: AppLocalizations.of(context).tutorOlderFailed,
      onRetry: () =>
          ref.read(tutorControllerProvider.notifier).loadOlder(retry: true),
    );
  }
}

class _NoActiveGoal extends StatelessWidget {
  const _NoActiveGoal();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StateMessage(
      icon: Icons.flag_outlined,
      title: l10n.tutorNoActiveGoal,
      actionLabel: l10n.manageGoals,
      onAction: () => context.go(AppRoutes.goals),
    );
  }
}
