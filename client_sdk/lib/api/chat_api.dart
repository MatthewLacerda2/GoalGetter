//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ChatApi {
  ChatApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create Message
  ///
  /// Create a new chat message for the authenticated user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateMessageRequest] createMessageRequest (required):
  Future<Response> createMessageApiV1ChatPostWithHttpInfo(CreateMessageRequest createMessageRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/chat';

    // ignore: prefer_final_locals
    Object? postBody = createMessageRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create Message
  ///
  /// Create a new chat message for the authenticated user.
  ///
  /// Parameters:
  ///
  /// * [CreateMessageRequest] createMessageRequest (required):
  Future<CreateMessageResponse?> createMessageApiV1ChatPost(CreateMessageRequest createMessageRequest,) async {
    final response = await createMessageApiV1ChatPostWithHttpInfo(createMessageRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CreateMessageResponse',) as CreateMessageResponse;
    
    }
    return null;
  }

  /// Delete Message
  ///
  /// Delete a message for the authenticated user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] messageId (required):
  Future<Response> deleteMessageApiV1ChatMessageIdDeleteWithHttpInfo(String messageId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/chat/{message_id}'
      .replaceAll('{message_id}', messageId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete Message
  ///
  /// Delete a message for the authenticated user.
  ///
  /// Parameters:
  ///
  /// * [String] messageId (required):
  Future<void> deleteMessageApiV1ChatMessageIdDelete(String messageId,) async {
    final response = await deleteMessageApiV1ChatMessageIdDeleteWithHttpInfo(messageId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Edit Message
  ///
  /// Edit a message for the authenticated user.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [EditMessageRequest] editMessageRequest (required):
  Future<Response> editMessageApiV1ChatEditPatchWithHttpInfo(EditMessageRequest editMessageRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/chat/edit';

    // ignore: prefer_final_locals
    Object? postBody = editMessageRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Edit Message
  ///
  /// Edit a message for the authenticated user.
  ///
  /// Parameters:
  ///
  /// * [EditMessageRequest] editMessageRequest (required):
  Future<ChatMessageItem?> editMessageApiV1ChatEditPatch(EditMessageRequest editMessageRequest,) async {
    final response = await editMessageApiV1ChatEditPatchWithHttpInfo(editMessageRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ChatMessageItem',) as ChatMessageItem;
    
    }
    return null;
  }

  /// Get Chat Messages
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] messageId:
  ///
  /// * [int] limit:
  Future<Response> getChatMessagesApiV1ChatGetWithHttpInfo({ String? messageId, int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/chat';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (messageId != null) {
      queryParams.addAll(_queryParams('', 'message_id', messageId));
    }
    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get Chat Messages
  ///
  /// Parameters:
  ///
  /// * [String] messageId:
  ///
  /// * [int] limit:
  Future<ChatMessageResponse?> getChatMessagesApiV1ChatGet({ String? messageId, int? limit, }) async {
    final response = await getChatMessagesApiV1ChatGetWithHttpInfo( messageId: messageId, limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ChatMessageResponse',) as ChatMessageResponse;
    
    }
    return null;
  }

  /// Like Message
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [LikeMessageRequest] likeMessageRequest (required):
  Future<Response> likeMessageApiV1ChatLikesPatchWithHttpInfo(LikeMessageRequest likeMessageRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/chat/likes';

    // ignore: prefer_final_locals
    Object? postBody = likeMessageRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PATCH',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Like Message
  ///
  /// Parameters:
  ///
  /// * [LikeMessageRequest] likeMessageRequest (required):
  Future<ChatMessageItem?> likeMessageApiV1ChatLikesPatch(LikeMessageRequest likeMessageRequest,) async {
    final response = await likeMessageApiV1ChatLikesPatchWithHttpInfo(likeMessageRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ChatMessageItem',) as ChatMessageItem;
    
    }
    return null;
  }
}
