import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/api.dart';

import 'package:goal_getter/features/tutor/domain/chat_message.dart';
import 'package:goal_getter/services/providers.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/mock_tutor_controller.dart';

class TutorState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final bool hasMoreMessages;
  final String? errorMessage;

  TutorState({
    this.messages = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.isSending = false,
    this.hasMoreMessages = true,
    this.errorMessage,
  });

  TutorState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    bool? hasMoreMessages,
    String? errorMessage,
  }) {
    return TutorState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      errorMessage: errorMessage,
    );
  }
}

class TutorNotifier extends StateNotifier<TutorState> {
  TutorNotifier(this._ref) : super(TutorState()) {
    fetchMessages();
  }

  final Ref _ref;
  String? _studentId;
  String? _oldestMessageId;
  final List<String> _pendingMessages = [];
  int _temporaryMessageCounter = 0;

  ChatMessage _convertToChatMessage(ChatMessageItem item) {
    final isUser = _studentId != null && item.senderId == _studentId;
    return ChatMessage(
      id: item.id,
      message: item.message,
      sender: isUser ? ChatMessageSender.user : ChatMessageSender.tutor,
      isLiked: item.isLiked,
    );
  }

  ChatMessage _convertResponseItemToChatMessage(ChatMessageResponseItem item) {
    final isUser = _studentId != null && item.senderId == _studentId;
    return ChatMessage(
      id: item.id,
      message: item.message,
      sender: isUser ? ChatMessageSender.user : ChatMessageSender.tutor,
      isLiked: item.isLiked,
    );
  }

  Future<void> fetchMessages({bool loadMore = false}) async {
    if (loadMore) return;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final mockMsgs = await getMockChatMessages();
      state = state.copyWith(
        messages: mockMsgs,
        isLoading: false,
        hasMoreMessages: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void submitMessage(String messageText) {
    final trimmed = messageText.trim();
    if (trimmed.isEmpty) return;

    _pendingMessages.add(trimmed);

    // Optimistic user update
    final tempId = 'temp_${_temporaryMessageCounter++}';
    final optimisticMsg = ChatMessage(
      id: tempId,
      message: trimmed,
      sender: ChatMessageSender.user,
      isLiked: false,
    );

    state = state.copyWith(
      messages: [...state.messages, optimisticMsg],
    );

    _sendPendingMessages();
  }

  Future<void> _sendPendingMessages() async {
    if (_pendingMessages.isEmpty || state.isSending) return;

    final userMsgText = _pendingMessages.first;
    _pendingMessages.clear();

    state = state.copyWith(isSending: true);

    try {
      final tutorReply = await getMockTutorResponse(userMsgText);
      final cleanedMessages = state.messages.where((msg) => !msg.id.startsWith('temp_')).toList();

      final userMsg = ChatMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        message: userMsgText,
        sender: ChatMessageSender.user,
      );

      state = state.copyWith(
        messages: [...cleanedMessages, userMsg, tutorReply],
        isSending: false,
      );
    } catch (e) {
      final cleanedMessages = state.messages.where((msg) => !msg.id.startsWith('temp_')).toList();
      state = state.copyWith(
        messages: cleanedMessages,
        isSending: false,
        errorMessage: 'Failed to send message: $e',
      );
    }
  }

  Future<void> toggleLikeMessage(String messageId, bool currentLikeStatus) async {
    final updatedList = state.messages.map((msg) {
      if (msg.id == messageId) {
        return ChatMessage(
          id: msg.id,
          message: msg.message,
          sender: msg.sender,
          isLiked: !currentLikeStatus,
        );
      }
      return msg;
    }).toList();

    state = state.copyWith(messages: updatedList);
  }
}

final tutorControllerProvider = StateNotifierProvider.autoDispose<TutorNotifier, TutorState>((ref) {
  return TutorNotifier(ref);
});
