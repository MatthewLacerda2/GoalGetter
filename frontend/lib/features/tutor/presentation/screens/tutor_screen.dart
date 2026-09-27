import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:goal_getter/app/router/app_routes.dart';
import 'package:goal_getter/core/widgets/failure.dart';
import 'package:goal_getter/core/widgets/state_message.dart';
import 'package:goal_getter/features/tutor/presentation/widgets/chat_bubbles.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_controller.dart';
import 'package:goal_getter/features/tutor/presentation/widgets/chat_input.dart';
import 'package:goal_getter/features/tutor/presentation/widgets/chat_message_bubble.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/core/theme/app_dimens.dart';

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
    final chat = ref.read(tutorControllerProvider).value;
    if (text.trim().isEmpty || (chat is TutorChat && chat.isSending)) return;
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
    final tutor = ref.watch(tutorControllerProvider);
    ref.listen(tutorControllerProvider, (previous, next) {
      if (_exchangeCount(previous?.value) != _exchangeCount(next.value)) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _loadOlderNearTop(),
        );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: tutor.when(
        // A retry loads the page again: the spinner, not the old failure.
        skipLoadingOnRefresh: false,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FailureView(
          error: error,
          title: AppLocalizations.of(context).tutorLoadFailed,
          onRetry: () => ref.invalidate(tutorControllerProvider),
        ),
        data: (state) => switch (state) {
          TutorNoActiveGoal() => const _NoActiveGoal(),
          TutorChat() => Column(
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
      ),
    );
  }

  int? _exchangeCount(TutorState? state) =>
      state is TutorChat ? state.exchanges.length : null;

  Widget _chat(TutorChat state) {
    final bubbles = chatBubbles(state.exchanges, state.pending);
    if (bubbles.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).tutorEmptyChat,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final showTop = switch (state.older) {
      LoadingOlderPages() || OlderPagesFailed() => true,
      NoOlderPages() || MoreOlderPages() => false,
    };
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.xs),
      itemCount: bubbles.length + (showTop ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == bubbles.length) return _OlderStatus(state.older);
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
  const _OlderStatus(this.older);

  final OlderPages older;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final older = this.older;
    if (older is! OlderPagesFailed) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return FailureView(
      error: older.cause,
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
