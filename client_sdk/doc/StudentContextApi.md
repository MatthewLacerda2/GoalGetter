# openapi.api.StudentContextApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createStudentContextApiV1StudentContextPost**](StudentContextApi.md#createstudentcontextapiv1studentcontextpost) | **POST** /api/v1/student-context | Create Student Context
[**deleteStudentContextApiV1StudentContextContextIdDelete**](StudentContextApi.md#deletestudentcontextapiv1studentcontextcontextiddelete) | **DELETE** /api/v1/student-context/{context_id} | Delete Student Context
[**getStudentContextsApiV1StudentContextGet**](StudentContextApi.md#getstudentcontextsapiv1studentcontextget) | **GET** /api/v1/student-context | Get Student Contexts


# **createStudentContextApiV1StudentContextPost**
> StudentContextItem createStudentContextApiV1StudentContextPost(createStudentContextRequest)

Create Student Context

Create a new student context

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StudentContextApi();
final createStudentContextRequest = CreateStudentContextRequest(); // CreateStudentContextRequest | 

try {
    final result = api_instance.createStudentContextApiV1StudentContextPost(createStudentContextRequest);
    print(result);
} catch (e) {
    print('Exception when calling StudentContextApi->createStudentContextApiV1StudentContextPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createStudentContextRequest** | [**CreateStudentContextRequest**](CreateStudentContextRequest.md)|  | 

### Return type

[**StudentContextItem**](StudentContextItem.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteStudentContextApiV1StudentContextContextIdDelete**
> deleteStudentContextApiV1StudentContextContextIdDelete(contextId)

Delete Student Context

Delete a student context

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StudentContextApi();
final contextId = contextId_example; // String | 

try {
    api_instance.deleteStudentContextApiV1StudentContextContextIdDelete(contextId);
} catch (e) {
    print('Exception when calling StudentContextApi->deleteStudentContextApiV1StudentContextContextIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **contextId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getStudentContextsApiV1StudentContextGet**
> StudentContextResponse getStudentContextsApiV1StudentContextGet()

Get Student Contexts

Get student contexts for the current user's objective

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StudentContextApi();

try {
    final result = api_instance.getStudentContextsApiV1StudentContextGet();
    print(result);
} catch (e) {
    print('Exception when calling StudentContextApi->getStudentContextsApiV1StudentContextGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**StudentContextResponse**](StudentContextResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

