# openapi.api.ActivitiesApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**takeMultipleChoiceActivityApiV1ActivitiesEvaluatePost**](ActivitiesApi.md#takemultiplechoiceactivityapiv1activitiesevaluatepost) | **POST** /api/v1/activities/evaluate | Take Multiple Choice Activity
[**takeMultipleChoiceActivityApiV1ActivitiesPost**](ActivitiesApi.md#takemultiplechoiceactivityapiv1activitiespost) | **POST** /api/v1/activities | Take Multiple Choice Activity


# **takeMultipleChoiceActivityApiV1ActivitiesEvaluatePost**
> MultipleChoiceActivityEvaluationResponse takeMultipleChoiceActivityApiV1ActivitiesEvaluatePost(multipleChoiceActivityEvaluationRequest)

Take Multiple Choice Activity

Takes the student's answers and informs the accuracy

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ActivitiesApi();
final multipleChoiceActivityEvaluationRequest = MultipleChoiceActivityEvaluationRequest(); // MultipleChoiceActivityEvaluationRequest | 

try {
    final result = api_instance.takeMultipleChoiceActivityApiV1ActivitiesEvaluatePost(multipleChoiceActivityEvaluationRequest);
    print(result);
} catch (e) {
    print('Exception when calling ActivitiesApi->takeMultipleChoiceActivityApiV1ActivitiesEvaluatePost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **multipleChoiceActivityEvaluationRequest** | [**MultipleChoiceActivityEvaluationRequest**](MultipleChoiceActivityEvaluationRequest.md)|  | 

### Return type

[**MultipleChoiceActivityEvaluationResponse**](MultipleChoiceActivityEvaluationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **takeMultipleChoiceActivityApiV1ActivitiesPost**
> MultipleChoiceActivityResponse takeMultipleChoiceActivityApiV1ActivitiesPost()

Take Multiple Choice Activity

Deliver a multiple choice activity to the current user.  It takes one from the DB or creates a new activity for the user if none exists.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = ActivitiesApi();

try {
    final result = api_instance.takeMultipleChoiceActivityApiV1ActivitiesPost();
    print(result);
} catch (e) {
    print('Exception when calling ActivitiesApi->takeMultipleChoiceActivityApiV1ActivitiesPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MultipleChoiceActivityResponse**](MultipleChoiceActivityResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

