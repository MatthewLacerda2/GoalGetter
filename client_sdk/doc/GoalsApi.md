# openapi.api.GoalsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteGoalApiV1GoalsGoalIdDelete**](GoalsApi.md#deletegoalapiv1goalsgoaliddelete) | **DELETE** /api/v1/goals/{goal_id} | Delete Goal
[**listGoalsApiV1GoalsGet**](GoalsApi.md#listgoalsapiv1goalsget) | **GET** /api/v1/goals | List Goals
[**setActiveGoalApiV1GoalsGoalIdSetActivePut**](GoalsApi.md#setactivegoalapiv1goalsgoalidsetactiveput) | **PUT** /api/v1/goals/{goal_id}/set-active | Set Active Goal


# **deleteGoalApiV1GoalsGoalIdDelete**
> deleteGoalApiV1GoalsGoalIdDelete(goalId)

Delete Goal

Delete a goal for the current student

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GoalsApi();
final goalId = goalId_example; // String | 

try {
    api_instance.deleteGoalApiV1GoalsGoalIdDelete(goalId);
} catch (e) {
    print('Exception when calling GoalsApi->deleteGoalApiV1GoalsGoalIdDelete: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **goalId** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listGoalsApiV1GoalsGet**
> ListGoalsResponse listGoalsApiV1GoalsGet()

List Goals

List all goals for the current student, ordered by latest objective update

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GoalsApi();

try {
    final result = api_instance.listGoalsApiV1GoalsGet();
    print(result);
} catch (e) {
    print('Exception when calling GoalsApi->listGoalsApiV1GoalsGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ListGoalsResponse**](ListGoalsResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **setActiveGoalApiV1GoalsGoalIdSetActivePut**
> StudentCurrentStatusResponse setActiveGoalApiV1GoalsGoalIdSetActivePut(goalId)

Set Active Goal

Set a goal as the active goal for the current student

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = GoalsApi();
final goalId = goalId_example; // String | 

try {
    final result = api_instance.setActiveGoalApiV1GoalsGoalIdSetActivePut(goalId);
    print(result);
} catch (e) {
    print('Exception when calling GoalsApi->setActiveGoalApiV1GoalsGoalIdSetActivePut: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **goalId** | **String**|  | 

### Return type

[**StudentCurrentStatusResponse**](StudentCurrentStatusResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

