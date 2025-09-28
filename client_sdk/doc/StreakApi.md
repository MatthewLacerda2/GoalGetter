# openapi.api.StreakApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getMonthStreakApiV1StreakStudentIdMonthGet**](StreakApi.md#getmonthstreakapiv1streakstudentidmonthget) | **GET** /api/v1/streak/{student_id}/month | Get Month Streak
[**getWeekStreakApiV1StreakStudentIdWeekGet**](StreakApi.md#getweekstreakapiv1streakstudentidweekget) | **GET** /api/v1/streak/{student_id}/week | Get Week Streak


# **getMonthStreakApiV1StreakStudentIdMonthGet**
> TimePeriodStreak getMonthStreakApiV1StreakStudentIdMonthGet(studentId, targetDate)

Get Month Streak

Get streak days for a specific month for a specific student

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = StreakApi();
final studentId = studentId_example; // String | 
final targetDate = 2013-10-20; // DateTime | 

try {
    final result = api_instance.getMonthStreakApiV1StreakStudentIdMonthGet(studentId, targetDate);
    print(result);
} catch (e) {
    print('Exception when calling StreakApi->getMonthStreakApiV1StreakStudentIdMonthGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **studentId** | **String**|  | 
 **targetDate** | **DateTime**|  | 

### Return type

[**TimePeriodStreak**](TimePeriodStreak.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getWeekStreakApiV1StreakStudentIdWeekGet**
> TimePeriodStreak getWeekStreakApiV1StreakStudentIdWeekGet(studentId)

Get Week Streak

Get streak days for the current week for a specific student

### Example
```dart
import 'package:openapi/api.dart';

final api_instance = StreakApi();
final studentId = studentId_example; // String | 

try {
    final result = api_instance.getWeekStreakApiV1StreakStudentIdWeekGet(studentId);
    print(result);
} catch (e) {
    print('Exception when calling StreakApi->getWeekStreakApiV1StreakStudentIdWeekGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **studentId** | **String**|  | 

### Return type

[**TimePeriodStreak**](TimePeriodStreak.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

