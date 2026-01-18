import 'dart:async';

import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../services/auth_service.dart';
import '../widgets/tutor/chat_input.dart';
import '../widgets/tutor/chat_message_bubble.dart';

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSending = false;
  bool _hasMoreMessages = true;
  String? _errorMessage;
  String? _studentId;
  String? _oldestMessageId;
  Timer? _debounceTimer;
  final List<String> _pendingMessages = [];
  int _temporaryMessageCounter = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _textController.addListener(_onTextChanged);
    _fetchMessages();
    // Scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onTextChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Set new timer to send after 1 second of no typing
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      if (_pendingMessages.isNotEmpty) {
        _sendPendingMessages();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // Detect when user scrolls near the top (within 200 pixels)
      if (_scrollController.position.pixels < 200 &&
          !_isLoadingMore &&
          _hasMoreMessages &&
          _oldestMessageId != null) {
        _fetchMessages(loadMore: true);
      }
    }
  }

  Future<void> _fetchMessages({bool loadMore = false}) async {
    if (loadMore &&
        (_isLoadingMore || !_hasMoreMessages || _oldestMessageId == null)) {
      return;
    }

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
      }
    });

    try {
      // Get the stored access token
      final accessToken = await _authService.getStoredAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available. Please sign in again.');
      }

      // Create API client and add the access token as Authorization header
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');

      // Fetch student status to get student_id if not already fetched
      if (_studentId == null) {
        final studentApi = StudentApi(apiClient);
        final studentResponse = await studentApi
            .getStudentCurrentStatusApiV1StudentGet();

        if (studentResponse == null) {
          throw Exception('Failed to fetch student status');
        }

        _studentId = studentResponse.studentId;
      }

      // Fetch chat messages
      final chatApi = ChatApi(apiClient);
      // For loading more, pass the oldest message ID to get messages before it
      final chatResponse = await chatApi.getChatMessagesApiV1ChatGet(
        messageId: loadMore ? _oldestMessageId : null,
        limit: 20,
      );

      if (mounted && chatResponse != null) {
        final newMessages = chatResponse.messages.reversed.toList();

        if (newMessages.isEmpty) {
          setState(() {
            _hasMoreMessages = false;
            if (loadMore) {
              _isLoadingMore = false;
            } else {
              _isLoading = false;
            }
          });
          return;
        }

        setState(() {
          if (loadMore) {
            // Prepend older messages to the beginning
            final convertedMessages = newMessages
                .map((msg) => _convertToChatMessage(msg))
                .toList();
            _messages.insertAll(0, convertedMessages);
            _isLoadingMore = false;
          } else {
            // Initial load - replace all messages
            _messages.clear();
            _messages.addAll(
              newMessages.map((msg) => _convertToChatMessage(msg)),
            );
            _isLoading = false;
          }

          // Update oldest message ID for next pagination
          if (_messages.isNotEmpty) {
            _oldestMessageId = _messages.first.id;
          }

          // Check if we got fewer messages than requested (no more to load)
          if (newMessages.length < 20) {
            _hasMoreMessages = false;
          }
        });

        if (!loadMore) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          if (loadMore) {
            _isLoadingMore = false;
          } else {
            _isLoading = false;
          }
        });
      }
    }
  }

  ChatMessage _convertToChatMessage(ChatMessageItem item) {
    // If sender_id == student_id, it's from the user, otherwise it's from the tutor
    final isUser = _studentId != null && item.senderId == _studentId;
    return ChatMessage(
      id: item.id,
      message: item.message,
      sender: isUser ? ChatMessageSender.user : ChatMessageSender.tutor,
      isLiked: item.isLiked,
    );
  }

  ChatMessage _convertResponseItemToChatMessage(ChatMessageResponseItem item) {
    // If sender_id == student_id, it's from the user, otherwise it's from the tutor
    final isUser = _studentId != null && item.senderId == _studentId;
    return ChatMessage(
      id: item.id,
      message: item.message,
      sender: isUser ? ChatMessageSender.user : ChatMessageSender.tutor,
      isLiked: item.isLiked,
    );
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

    // Add to pending messages
    setState(() {
      _pendingMessages.add(messageText);
      // Add optimistic message to UI immediately
      final tempId = 'temp_${_temporaryMessageCounter++}';
      _messages.add(
        ChatMessage(
          id: tempId,
          message: messageText,
          sender: ChatMessageSender.user,
          isLiked: false,
        ),
      );
    });

    // Clear input immediately
    _textController.clear();

    // Scroll to bottom to show new message
    _scrollToBottom();

    // Cancel previous timer and set new one
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      if (_pendingMessages.isNotEmpty) {
        _sendPendingMessages();
      }
    });
  }

  Future<void> _sendPendingMessages() async {
    if (_pendingMessages.isEmpty || _isSending) return;

    // Get all pending messages to send
    final messagesToSend = List<String>.from(_pendingMessages);
    _pendingMessages.clear();

    setState(() {
      _isSending = true;
    });

    try {
      // Get the stored access token
      final accessToken = await _authService.getStoredAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available. Please sign in again.');
      }

      // Create API client and add the access token as Authorization header
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');

      final chatApi = ChatApi(apiClient);

      // Create the request with all pending messages in sequence
      final request = CreateMessageRequest(
        messagesList: messagesToSend
            .map(
              (msg) => CreateMessageRequestItem(
                message: msg,
                datetime: DateTime.now(),
              ),
            )
            .toList(),
      );

      // Send messages to API
      final response = await chatApi.createMessageApiV1ChatPost(request);

      if (mounted && response != null && response.messages.isNotEmpty) {
        // Remove temporary user messages and add real messages from response
        setState(() {
          // Remove all temporary user messages
          _messages.removeWhere(
            (msg) =>
                msg.id.startsWith('temp_') &&
                msg.sender == ChatMessageSender.user,
          );
        });

        // Convert all response messages
        final responseMessages = response.messages
            .map((item) => _convertResponseItemToChatMessage(item))
            .toList();

        // Add first message immediately
        if (responseMessages.isNotEmpty) {
          setState(() {
            _messages.add(responseMessages[0]);
          });
          _scrollToBottom();
        }

        // Add subsequent messages with 0.5s delay after each previous one
        for (int i = 1; i < responseMessages.length; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            setState(() {
              _messages.add(responseMessages[i]);
            });
            _scrollToBottom();
          }
        }
      } else {
        // If no response, refetch messages to sync with server
        await _fetchMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send message: ${e.toString()}';
          // Remove temporary messages on error
          _messages.removeWhere(
            (msg) =>
                msg.id.startsWith('temp_') &&
                msg.sender == ChatMessageSender.user,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _toggleLikeMessage(
    String messageId,
    bool currentLikeStatus,
  ) async {
    // Don't allow liking temporary messages (they don't exist on server yet)
    if (messageId.startsWith('temp_')) {
      return;
    }

    // Optimistically update the UI
    setState(() {
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        _messages[messageIndex] = ChatMessage(
          id: message.id,
          message: message.message,
          sender: message.sender,
          isLiked: !currentLikeStatus,
        );
      }
    });

    try {
      // Get the stored access token
      final accessToken = await _authService.getStoredAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available. Please sign in again.');
      }

      // Create API client and add the access token as Authorization header
      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');

      final chatApi = ChatApi(apiClient);

      // Create the like request
      final request = LikeMessageRequest(
        messageId: messageId,
        like: !currentLikeStatus,
      );

      // Send like/unlike request to API
      final response = await chatApi.likeMessageApiV1ChatLikesPatch(request);

      if (mounted && response != null) {
        // Update with the actual response from server
        setState(() {
          final messageIndex = _messages.indexWhere(
            (msg) => msg.id == messageId,
          );
          if (messageIndex != -1) {
            final message = _messages[messageIndex];
            _messages[messageIndex] = ChatMessage(
              id: message.id,
              message: message.message,
              sender: message.sender,
              isLiked: response.isLiked,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        // Revert optimistic update on error
        setState(() {
          final messageIndex = _messages.indexWhere(
            (msg) => msg.id == messageId,
          );
          if (messageIndex != -1) {
            final message = _messages[messageIndex];
            _messages[messageIndex] = ChatMessage(
              id: message.id,
              message: message.message,
              sender: message.sender,
              isLiked: currentLikeStatus,
            );
          }
        });
        setState(() {
          _errorMessage = 'Failed to like message: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Show loading indicator at top when loading more messages
          if (_isLoadingMore)
            Container(
              padding: const EdgeInsets.all(8),
              child: const Center(child: CircularProgressIndicator()),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: $_errorMessage',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _fetchMessages(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'New chat',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatMessageBubble(
                        message: message,
                        onDoubleTap: () =>
                            _toggleLikeMessage(message.id, message.isLiked),
                      );
                    },
                  ),
          ),
          ChatInput(
            controller: _textController,
            onSendMessage: _handleMessageSubmitted,
            isSending: _isSending,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
