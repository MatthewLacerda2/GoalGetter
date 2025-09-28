# openapi.api.AssessmentsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**subjectiveQuestionEvaluationApiV1AssessmentsEvaluateSingleQuestionPost**](AssessmentsApi.md#subjectivequestionevaluationapiv1assessmentsevaluatesinglequestionpost) | **POST** /api/v1/assessments/evaluate/single_question | Subjective Question Evaluation
[**subjectiveQuestionsOverallEvaluationApiV1AssessmentsEvaluateOverallPost**](AssessmentsApi.md#subjectivequestionsoverallevaluationapiv1assessmentsevaluateoverallpost) | **POST** /api/v1/assessments/evaluate/overall | Subjective Questions Overall Evaluation
[**takeSubjectiveQuestionsAssessmentApiV1AssessmentsPost**](AssessmentsApi.md#takesubjectivequestionsassessmentapiv1assessmentspost) | **POST** /api/v1/assessments | Take Subjective Questions Assessment


# **subjectiveQuestionEvaluationApiV1AssessmentsEvaluateSingleQuestionPost**
> SubjectiveQuestionEvaluationResponse subjectiveQuestionEvaluationApiV1AssessmentsEvaluateSingleQuestionPost(subjectiveQuestionEvaluationRequest)

Subjective Question Evaluation

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AssessmentsApi();
final subjectiveQuestionEvaluationRequest = SubjectiveQuestionEvaluationRequest(); // SubjectiveQuestionEvaluationRequest | 

try {
    final result = api_instance.subjectiveQuestionEvaluationApiV1AssessmentsEvaluateSingleQuestionPost(subjectiveQuestionEvaluationRequest);
    print(result);
} catch (e) {
    print('Exception when calling AssessmentsApi->subjectiveQuestionEvaluationApiV1AssessmentsEvaluateSingleQuestionPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **subjectiveQuestionEvaluationRequest** | [**SubjectiveQuestionEvaluationRequest**](SubjectiveQuestionEvaluationRequest.md)|  | 

### Return type

[**SubjectiveQuestionEvaluationResponse**](SubjectiveQuestionEvaluationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **subjectiveQuestionsOverallEvaluationApiV1AssessmentsEvaluateOverallPost**
> SubjectiveQuestionsAssessmentEvaluationResponse subjectiveQuestionsOverallEvaluationApiV1AssessmentsEvaluateOverallPost(subjectiveQuestionsAssessmentEvaluationRequest)

Subjective Questions Overall Evaluation

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AssessmentsApi();
final subjectiveQuestionsAssessmentEvaluationRequest = SubjectiveQuestionsAssessmentEvaluationRequest(); // SubjectiveQuestionsAssessmentEvaluationRequest | 

try {
    final result = api_instance.subjectiveQuestionsOverallEvaluationApiV1AssessmentsEvaluateOverallPost(subjectiveQuestionsAssessmentEvaluationRequest);
    print(result);
} catch (e) {
    print('Exception when calling AssessmentsApi->subjectiveQuestionsOverallEvaluationApiV1AssessmentsEvaluateOverallPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **subjectiveQuestionsAssessmentEvaluationRequest** | [**SubjectiveQuestionsAssessmentEvaluationRequest**](SubjectiveQuestionsAssessmentEvaluationRequest.md)|  | 

### Return type

[**SubjectiveQuestionsAssessmentEvaluationResponse**](SubjectiveQuestionsAssessmentEvaluationResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **takeSubjectiveQuestionsAssessmentApiV1AssessmentsPost**
> SubjectiveQuestionsAssessmentResponse takeSubjectiveQuestionsAssessmentApiV1AssessmentsPost()

Take Subjective Questions Assessment

Deliver a subjective questions assessment to the current user.  It takes one from the DB or creates a new assessment for the user if none exists.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AssessmentsApi();

try {
    final result = api_instance.takeSubjectiveQuestionsAssessmentApiV1AssessmentsPost();
    print(result);
} catch (e) {
    print('Exception when calling AssessmentsApi->takeSubjectiveQuestionsAssessmentApiV1AssessmentsPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SubjectiveQuestionsAssessmentResponse**](SubjectiveQuestionsAssessmentResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

