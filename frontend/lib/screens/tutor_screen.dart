import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../widgets/error_retry_widget.dart';
import '../widgets/tutor/chat_input.dart';
import '../widgets/tutor/chat_message_bubble.dart';
import 'tutor_controller.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

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
        duration: const Duration(milliseconds: 300),
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
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          if (state.isLoadingMore)
            Container(
              padding: const EdgeInsets.all(AppTheme.edgePadding),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.accentPrimary,
                ),
              ),
            ),
          Expanded(
            child: state.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentPrimary,
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
                        ? const Center(
                            child: Text(
                              'New chat',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontSize14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                                bottom: AppTheme.spacing8),
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
