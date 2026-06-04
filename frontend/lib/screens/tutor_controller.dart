import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openapi/api.dart';

import '../models/chat_message.dart';
import '../services/providers.dart';

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
    if (loadMore && (state.isLoadingMore || !state.hasMoreMessages || _oldestMessageId == null)) {
      return;
    }

    state = state.copyWith(
      isLoading: !loadMore,
      isLoadingMore: loadMore,
    );

    try {
      final apiClient = await _ref.read(apiClientProvider.future);
      
      if (_studentId == null) {
        final studentApi = StudentApi(apiClient);
        final studentResponse = await studentApi.getStudentCurrentStatusApiV1StudentGet();
        if (studentResponse == null) {
          throw Exception('Failed to fetch student status');
        }
        _studentId = studentResponse.studentId;
      }

      final chatApi = ChatApi(apiClient);
      final chatResponse = await chatApi.getChatMessagesApiV1ChatGet(
        messageId: loadMore ? _oldestMessageId : null,
        limit: 20,
      );

      if (chatResponse != null) {
        final newMessages = chatResponse.messages.reversed.toList();
        if (newMessages.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            hasMoreMessages: false,
          );
          return;
        }

        final convertedList = newMessages.map((msg) => _convertToChatMessage(msg)).toList();
        final List<ChatMessage> updatedMessages;
        if (loadMore) {
          updatedMessages = [...convertedList, ...state.messages];
        } else {
          updatedMessages = convertedList;
        }

        if (updatedMessages.isNotEmpty) {
          _oldestMessageId = updatedMessages.first.id;
        }

        state = state.copyWith(
          messages: updatedMessages,
          isLoading: false,
          isLoadingMore: false,
          hasMoreMessages: newMessages.length == 20,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
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

    final messagesToSend = List<String>.from(_pendingMessages);
    _pendingMessages.clear();

    state = state.copyWith(isSending: true);

    try {
      final apiClient = await _ref.read(apiClientProvider.future);
      final chatApi = ChatApi(apiClient);

      final request = CreateMessageRequest(
        messagesList: messagesToSend
            .map((msg) => CreateMessageRequestItem(
                  message: msg,
                  datetime: DateTime.now(),
                ))
            .toList(),
      );

      final response = await chatApi.createMessageApiV1ChatPost(request);

      if (response != null && response.messages.isNotEmpty) {
        final cleanedMessages = state.messages.where((msg) => !msg.id.startsWith('temp_')).toList();

        final responseMessages = response.messages
            .map((item) => _convertResponseItemToChatMessage(item))
            .toList();

        state = state.copyWith(
          messages: [...cleanedMessages, responseMessages.first],
          isSending: false,
        );

        for (int i = 1; i < responseMessages.length; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          state = state.copyWith(
            messages: [...state.messages, responseMessages[i]],
          );
        }
      } else {
        await fetchMessages();
      }
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
    if (messageId.startsWith('temp_')) return;

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

    try {
      final apiClient = await _ref.read(apiClientProvider.future);
      final chatApi = ChatApi(apiClient);

      final request = LikeMessageRequest(
        messageId: messageId,
        like: !currentLikeStatus,
      );

      final response = await chatApi.likeMessageApiV1ChatLikesPatch(request);
      if (response != null) {
        final syncedList = state.messages.map((msg) {
          if (msg.id == messageId) {
            return ChatMessage(
              id: msg.id,
              message: msg.message,
              sender: msg.sender,
              isLiked: response.isLiked,
            );
          }
          return msg;
        }).toList();
        state = state.copyWith(messages: syncedList);
      }
    } catch (e) {
      final revertedList = state.messages.map((msg) {
        if (msg.id == messageId) {
          return ChatMessage(
            id: msg.id,
            message: msg.message,
            sender: msg.sender,
            isLiked: currentLikeStatus,
          );
        }
        return msg;
      }).toList();
      state = state.copyWith(
        messages: revertedList,
        errorMessage: 'Failed to like message: $e',
      );
    }
  }
}

final tutorControllerProvider = StateNotifierProvider.autoDispose<TutorNotifier, TutorState>((ref) {
  return TutorNotifier(ref);
});
