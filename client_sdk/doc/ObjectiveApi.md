# openapi.api.ObjectiveApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getObjectiveApiV1ObjectiveGet**](ObjectiveApi.md#getobjectiveapiv1objectiveget) | **GET** /api/v1/objective | Get Objective
[**getObjectivesListApiV1ObjectiveListGet**](ObjectiveApi.md#getobjectiveslistapiv1objectivelistget) | **GET** /api/v1/objective/list | Get Objectives List


# **getObjectiveApiV1ObjectiveGet**
> ObjectiveResponse getObjectiveApiV1ObjectiveGet()

Get Objective

Get the latest objective for the current user

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ObjectiveApi();

try {
    final result = api_instance.getObjectiveApiV1ObjectiveGet();
    print(result);
} catch (e) {
    print('Exception when calling ObjectiveApi->getObjectiveApiV1ObjectiveGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ObjectiveResponse**](ObjectiveResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getObjectivesListApiV1ObjectiveListGet**
> ObjectiveListResponse getObjectivesListApiV1ObjectiveListGet()

Get Objectives List

Get all objectives for the current user's goal

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ObjectiveApi();

try {
    final result = api_instance.getObjectivesListApiV1ObjectiveListGet();
    print(result);
} catch (e) {
    print('Exception when calling ObjectiveApi->getObjectivesListApiV1ObjectiveListGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ObjectiveListResponse**](ObjectiveListResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

