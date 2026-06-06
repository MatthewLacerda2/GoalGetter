import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goal_getter/core/widgets/error_retry_widget.dart';
import 'package:goal_getter/features/tutor/presentation/widgets/chat_input.dart';
import 'package:goal_getter/features/tutor/presentation/widgets/chat_message_bubble.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_controller.dart';

class TutorScreen extends ConsumerStatefulWidget {
  TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      if (_scrollController.position.pixels < 200) {
        ref.read(tutorControllerProvider.notifier).fetchMessages(loadMore: true);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleMessageSubmitted() {
    final messageText = _textController.text.trim();
    if (messageText.isEmpty) return;

    ref.read(tutorControllerProvider.notifier).submitMessage(messageText);
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorControllerProvider);

    // Auto-scroll when new messages arrive
    ref.listen(tutorControllerProvider, (previous, next) {
      if (previous != null && previous.messages.length < next.messages.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          if (state.isLoadingMore)
            Container(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          Expanded(
            child: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : state.errorMessage != null
                    ? ErrorRetryWidget(
                        errorMessage: state.errorMessage!,
                        onRetry: () => ref
                            .read(tutorControllerProvider.notifier)
                            .fetchMessages(),
                      )
                    : state.messages.isEmpty
                        ? Center(
                            child: Text(
                              'New chat',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 14.0,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.only(
                                bottom: 8.0),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              return ChatMessageBubble(
                                message: message,
                                onDoubleTap: () => ref
                                    .read(tutorControllerProvider.notifier)
                                    .toggleLikeMessage(
                                        message.id, message.isLiked),
                              );
                            },
                          ),
          ),
          ChatInput(
            controller: _textController,
            onSendMessage: _handleMessageSubmitted,
            isSending: state.isSending,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
