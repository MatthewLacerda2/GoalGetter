# openapi.api.StudentApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getStudentCurrentStatusApiV1StudentGet**](StudentApi.md#getstudentcurrentstatusapiv1studentget) | **GET** /api/v1/student | Get Student Current Status


# **getStudentCurrentStatusApiV1StudentGet**
> StudentCurrentStatusResponse getStudentCurrentStatusApiV1StudentGet()

Get Student Current Status

Get the current status of the student

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = StudentApi();

try {
    final result = api_instance.getStudentCurrentStatusApiV1StudentGet();
    print(result);
} catch (e) {
    print('Exception when calling StudentApi->getStudentCurrentStatusApiV1StudentGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**StudentCurrentStatusResponse**](StudentCurrentStatusResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

