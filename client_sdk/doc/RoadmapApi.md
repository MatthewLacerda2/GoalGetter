# openapi.api.RoadmapApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createRoadmapApiV1RoadmapCreationPost**](RoadmapApi.md#createroadmapapiv1roadmapcreationpost) | **POST** /api/v1/roadmap/creation | Create Roadmap
[**initiateRoadmapApiV1RoadmapInitiationPost**](RoadmapApi.md#initiateroadmapapiv1roadmapinitiationpost) | **POST** /api/v1/roadmap/initiation | Initiate Roadmap


# **createRoadmapApiV1RoadmapCreationPost**
> RoadmapCreationResponse createRoadmapApiV1RoadmapCreationPost(roadmapCreationRequest)

Create Roadmap

Create a roadmap based on the user's goal and follow-up questions.

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoadmapApi();
final roadmapCreationRequest = RoadmapCreationRequest(); // RoadmapCreationRequest | 

try {
    final result = api_instance.createRoadmapApiV1RoadmapCreationPost(roadmapCreationRequest);
    print(result);
} catch (e) {
    print('Exception when calling RoadmapApi->createRoadmapApiV1RoadmapCreationPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roadmapCreationRequest** | [**RoadmapCreationRequest**](RoadmapCreationRequest.md)|  | 

### Return type

[**RoadmapCreationResponse**](RoadmapCreationResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **initiateRoadmapApiV1RoadmapInitiationPost**
> RoadmapInitiationResponse initiateRoadmapApiV1RoadmapInitiationPost(roadmapInitiationRequest)

Initiate Roadmap

Initiate the roadmap creation process by analyzing the user's goal prompt and generating follow-up questions.

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = RoadmapApi();
final roadmapInitiationRequest = RoadmapInitiationRequest(); // RoadmapInitiationRequest | 

try {
    final result = api_instance.initiateRoadmapApiV1RoadmapInitiationPost(roadmapInitiationRequest);
    print(result);
} catch (e) {
    print('Exception when calling RoadmapApi->initiateRoadmapApiV1RoadmapInitiationPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **roadmapInitiationRequest** | [**RoadmapInitiationRequest**](RoadmapInitiationRequest.md)|  | 

### Return type

[**RoadmapInitiationResponse**](RoadmapInitiationResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

