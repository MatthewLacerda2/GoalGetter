# openapi.api.ResourcesApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getResourcesApiV1ResourcesGet**](ResourcesApi.md#getresourcesapiv1resourcesget) | **GET** /api/v1/resources | Get Resources


# **getResourcesApiV1ResourcesGet**
> ResourceResponse getResourcesApiV1ResourcesGet(goalId)

Get Resources

Get all resources for a specific goal

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = ResourcesApi();
final goalId = goalId_example; // String | Goal ID to filter resources by

try {
    final result = api_instance.getResourcesApiV1ResourcesGet(goalId);
    print(result);
} catch (e) {
    print('Exception when calling ResourcesApi->getResourcesApiV1ResourcesGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **goalId** | **String**| Goal ID to filter resources by | 

### Return type

[**ResourceResponse**](ResourceResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

