# openapi.api.AchievementsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAchievementsApiV1AchievementsStudentIdGet**](AchievementsApi.md#getachievementsapiv1achievementsstudentidget) | **GET** /api/v1/achievements/{student_id} | Get Achievements
[**getLeaderboardApiV1AchievementsLeaderboardGet**](AchievementsApi.md#getleaderboardapiv1achievementsleaderboardget) | **GET** /api/v1/achievements/leaderboard | Get Leaderboard
[**getXpByDaysApiV1AchievementsXpByDaysGet**](AchievementsApi.md#getxpbydaysapiv1achievementsxpbydaysget) | **GET** /api/v1/achievements/xp_by_days | Get Xp By Days


# **getAchievementsApiV1AchievementsStudentIdGet**
> PlayerAchievementResponse getAchievementsApiV1AchievementsStudentIdGet(studentId, limit)

Get Achievements

Get achievements for a specific student

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = AchievementsApi();
final studentId = studentId_example; // String | 
final limit = 56; // int | Limit number of achievements returned

try {
    final result = api_instance.getAchievementsApiV1AchievementsStudentIdGet(studentId, limit);
    print(result);
} catch (e) {
    print('Exception when calling AchievementsApi->getAchievementsApiV1AchievementsStudentIdGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **studentId** | **String**|  | 
 **limit** | **int**| Limit number of achievements returned | [optional] 

### Return type

[**PlayerAchievementResponse**](PlayerAchievementResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getLeaderboardApiV1AchievementsLeaderboardGet**
> LeaderboardResponse getLeaderboardApiV1AchievementsLeaderboardGet()

Get Leaderboard

Get the leaderboard around the current user's XP level

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AchievementsApi();

try {
    final result = api_instance.getLeaderboardApiV1AchievementsLeaderboardGet();
    print(result);
} catch (e) {
    print('Exception when calling AchievementsApi->getLeaderboardApiV1AchievementsLeaderboardGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**LeaderboardResponse**](LeaderboardResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getXpByDaysApiV1AchievementsXpByDaysGet**
> XpByDaysResponse getXpByDaysApiV1AchievementsXpByDaysGet(days)

Get Xp By Days

Get XP data for the current user over the last X days

### Example
```dart
import 'package:openapi/api.dart';
// TODO Configure HTTP Bearer authorization: HTTPBearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('HTTPBearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AchievementsApi();
final days = 56; // int | Number of days to look back

try {
    final result = api_instance.getXpByDaysApiV1AchievementsXpByDaysGet(days);
    print(result);
} catch (e) {
    print('Exception when calling AchievementsApi->getXpByDaysApiV1AchievementsXpByDaysGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **days** | **int**| Number of days to look back | [optional] [default to 30]

### Return type

[**XpByDaysResponse**](XpByDaysResponse.md)

### Authorization

[HTTPBearer](../README.md#HTTPBearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

