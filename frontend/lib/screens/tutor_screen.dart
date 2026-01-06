import 'package:flutter/material.dart';
import 'package:openapi/api.dart';
import '../widgets/tutor/chat_message_bubble.dart';
import '../models/chat_message.dart';
import '../widgets/tutor/chat_input.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchMessages();
    // Scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
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
    if (loadMore && (_isLoadingMore || !_hasMoreMessages || _oldestMessageId == null)) {
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
        final studentResponse = await studentApi.getStudentCurrentStatusApiV1StudentGet();
        
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
            final convertedMessages = newMessages.map((msg) => _convertToChatMessage(msg)).toList();
            _messages.insertAll(0, convertedMessages);
            _isLoadingMore = false;
          } else {
            // Initial load - replace all messages
            _messages.clear();
            _messages.addAll(newMessages.map((msg) => _convertToChatMessage(msg)));
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
    );
  }

  ChatMessage _convertResponseItemToChatMessage(ChatMessageResponseItem item) {
    // If sender_id == student_id, it's from the user, otherwise it's from the tutor
    final isUser = _studentId != null && item.senderId == _studentId;
    return ChatMessage(
      id: item.id,
      message: item.message,
      sender: isUser ? ChatMessageSender.user : ChatMessageSender.tutor,
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

  Future<void> _sendMessage() async {
    final messageText = _textController.text.trim();
    if (messageText.isEmpty || _isSending) return;

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
      
      // Create the request with the user's message
      final request = CreateMessageRequest(
        messagesList: [
          CreateMessageRequestItem(
            message: messageText,
            datetime: DateTime.now(),
          ),
        ],
      );

      // Clear input immediately for better UX
      _textController.clear();

      // Send message to API
      await chatApi.createMessageApiV1ChatPost(request);

      // Refetch all messages to get the updated conversation
      await _fetchMessages();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send message: ${e.toString()}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Show loading indicator at top when loading more messages
          if (_isLoadingMore)
            Container(
              padding: const EdgeInsets.all(8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
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
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return ChatMessageBubble(message: message);
                        },
                      ),
          ),
          ChatInput(
            controller: _textController,
            onSendMessage: _sendMessage,
            isSending: _isSending,
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

