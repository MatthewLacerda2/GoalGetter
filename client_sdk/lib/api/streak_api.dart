//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class StreakApi {
  StreakApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get Month Streak
  ///
  /// Get streak days for a specific month for a specific student
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] studentId (required):
  ///
  /// * [DateTime] targetDate (required):
  Future<Response> getMonthStreakApiV1StreakStudentIdMonthGetWithHttpInfo(String studentId, DateTime targetDate,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/streak/{student_id}/month'
      .replaceAll('{student_id}', studentId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'target_date', targetDate));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get Month Streak
  ///
  /// Get streak days for a specific month for a specific student
  ///
  /// Parameters:
  ///
  /// * [String] studentId (required):
  ///
  /// * [DateTime] targetDate (required):
  Future<TimePeriodStreak?> getMonthStreakApiV1StreakStudentIdMonthGet(String studentId, DateTime targetDate,) async {
    final response = await getMonthStreakApiV1StreakStudentIdMonthGetWithHttpInfo(studentId, targetDate,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TimePeriodStreak',) as TimePeriodStreak;
    
    }
    return null;
  }

  /// Get Week Streak
  ///
  /// Get streak days for the current week for a specific student
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] studentId (required):
  Future<Response> getWeekStreakApiV1StreakStudentIdWeekGetWithHttpInfo(String studentId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/streak/{student_id}/week'
      .replaceAll('{student_id}', studentId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get Week Streak
  ///
  /// Get streak days for the current week for a specific student
  ///
  /// Parameters:
  ///
  /// * [String] studentId (required):
  Future<TimePeriodStreak?> getWeekStreakApiV1StreakStudentIdWeekGet(String studentId,) async {
    final response = await getWeekStreakApiV1StreakStudentIdWeekGetWithHttpInfo(studentId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TimePeriodStreak',) as TimePeriodStreak;
    
    }
    return null;
  }
}
