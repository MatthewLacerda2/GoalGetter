# openapi.api.ChatApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createMessageApiV1ChatPost**](ChatApi.md#createmessageapiv1chatpost) | **POST** /api/v1/chat | Create Message
[**deleteMessageApiV1ChatMessageIdDelete**](ChatApi.md#deletemessageapiv1chatmessageiddelete) | **DELETE** /api/v1/chat/{message_id} | Delete Message
[**editMessageApiV1ChatEditPatch**](ChatApi.md#editmessageapiv1chateditpatch) | **PATCH** /api/v1/chat/edit | Edit Message
[**getChatMessagesApiV1ChatGet**](ChatApi.md#getchatmessagesapiv1chatget) | **GET** /api/v1/chat | Get Chat Messages
[**likeMessageApiV1ChatLikesPatch**](ChatApi.md#likemessageapiv1chatlikespatch) | **PATCH** /api/v1/chat/likes | Like Message


# **createMessageApiV1ChatPost**
> CreateMessageResponse createMessageApiV1ChatPost(createMessageRequest)

Create Message

Create a new chat message for the authenticated user.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ChatApi();
final createMessageRequest = CreateMessageRequest(); // CreateMessageRequest | 

try {
    final result = api_instance.createMessageApiV1ChatPost(createMessageRequest);
    print(result);
} catch (e) {
    print('Exception when calling ChatApi->createMessageApiV1ChatPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createMessageRequest** | [**CreateMessageRequest**](CreateMessageRequest.md)|  | 

### Return type

[**CreateMessageResponse**](CreateMessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMessageApiV1ChatMessageIdDelete**
> deleteMessageApiV1ChatMessageIdDelete(messageId)

Delete Message

Delete a message for the authenticated user.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ChatApi();
final messageId = messageId_example; // String | 

try {
    api_instance.deleteMessageApiV1ChatMessageIdDelete(messageId);
} catch (e) {
    print('Exception when calling ChatApi->deleteMessageApiV1ChatMessageIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **editMessageApiV1ChatEditPatch**
> ChatMessageItem editMessageApiV1ChatEditPatch(editMessageRequest)

Edit Message

Edit a message for the authenticated user.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ChatApi();
final editMessageRequest = EditMessageRequest(); // EditMessageRequest | 

try {
    final result = api_instance.editMessageApiV1ChatEditPatch(editMessageRequest);
    print(result);
} catch (e) {
    print('Exception when calling ChatApi->editMessageApiV1ChatEditPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **editMessageRequest** | [**EditMessageRequest**](EditMessageRequest.md)|  | 

### Return type

[**ChatMessageItem**](ChatMessageItem.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getChatMessagesApiV1ChatGet**
> ChatMessageResponse getChatMessagesApiV1ChatGet(messageId, limit)

Get Chat Messages

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ChatApi();
final messageId = messageId_example; // String | 
final limit = 56; // int | 

try {
    final result = api_instance.getChatMessagesApiV1ChatGet(messageId, limit);
    print(result);
} catch (e) {
    print('Exception when calling ChatApi->getChatMessagesApiV1ChatGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **messageId** | **String**|  | [optional] 
 **limit** | **int**|  | [optional] 

### Return type

[**ChatMessageResponse**](ChatMessageResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **likeMessageApiV1ChatLikesPatch**
> ChatMessageItem likeMessageApiV1ChatLikesPatch(likeMessageRequest)

Like Message

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ChatApi();
final likeMessageRequest = LikeMessageRequest(); // LikeMessageRequest | 

try {
    final result = api_instance.likeMessageApiV1ChatLikesPatch(likeMessageRequest);
    print(result);
} catch (e) {
    print('Exception when calling ChatApi->likeMessageApiV1ChatLikesPatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **likeMessageRequest** | [**LikeMessageRequest**](LikeMessageRequest.md)|  | 

### Return type

[**ChatMessageItem**](ChatMessageItem.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

