# openapi.api.DefaultApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**llmsTxtLlmsTxtGet**](DefaultApi.md#llmstxtllmstxtget) | **GET** /llms.txt | Llms Txt
[**rootApiV1CheckGet**](DefaultApi.md#rootapiv1checkget) | **GET** /api/v1/check | Root
[**securityTxtFallbackSecurityTxtGet**](DefaultApi.md#securitytxtfallbacksecuritytxtget) | **GET** /security.txt | Security Txt Fallback


# **llmsTxtLlmsTxtGet**
> String llmsTxtLlmsTxtGet()

Llms Txt

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.llmsTxtLlmsTxtGet();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->llmsTxtLlmsTxtGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rootApiV1CheckGet**
> Object rootApiV1CheckGet()

Root

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.rootApiV1CheckGet();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->rootApiV1CheckGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Object**](Object.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **securityTxtFallbackSecurityTxtGet**
> String securityTxtFallbackSecurityTxtGet()

Security Txt Fallback

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = DefaultApi();

try {
    final result = api_instance.securityTxtFallbackSecurityTxtGet();
    print(result);
} catch (e) {
    print('Exception when calling DefaultApi->securityTxtFallbackSecurityTxtGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

**String**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: text/plain

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

