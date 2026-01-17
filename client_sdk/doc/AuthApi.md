# openapi.api.AuthApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deleteAccountApiV1AuthAccountDelete**](AuthApi.md#deleteaccountapiv1authaccountdelete) | **DELETE** /api/v1/auth/account | Delete Account
[**loginApiV1AuthLoginPost**](AuthApi.md#loginapiv1authloginpost) | **POST** /api/v1/auth/login | Login


# **deleteAccountApiV1AuthAccountDelete**
> deleteAccountApiV1AuthAccountDelete()

Delete Account

Delete user account and all associated data. Database CASCADE will automatically delete related goals and their objectives. Use bulk delete to bypass ORM relationship handling which causes constraint violations.

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AuthApi();

try {
    api_instance.deleteAccountApiV1AuthAccountDelete();
} catch (e) {
    print('Exception when calling AuthApi->deleteAccountApiV1AuthAccountDelete: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **loginApiV1AuthLoginPost**
> TokenResponse loginApiV1AuthLoginPost(oAuth2Request)

Login

Login using Google OAuth2 token.

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AuthApi();
final oAuth2Request = OAuth2Request(); // OAuth2Request | 

try {
    final result = api_instance.loginApiV1AuthLoginPost(oAuth2Request);
    print(result);
} catch (e) {
    print('Exception when calling AuthApi->loginApiV1AuthLoginPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **oAuth2Request** | [**OAuth2Request**](OAuth2Request.md)|  | 

### Return type

[**TokenResponse**](TokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

