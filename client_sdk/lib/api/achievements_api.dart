//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AchievementsApi {
  AchievementsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get Achievements
  ///
  /// Get achievements for a specific student
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] studentId (required):
  ///
  /// * [int] limit:
  ///   Limit number of achievements returned
  Future<Response> getAchievementsApiV1AchievementsStudentIdGetWithHttpInfo(String studentId, { int? limit, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/achievements/{student_id}'
      .replaceAll('{student_id}', studentId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (limit != null) {
      queryParams.addAll(_queryParams('', 'limit', limit));
    }

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

  /// Get Achievements
  ///
  /// Get achievements for a specific student
  ///
  /// Parameters:
  ///
  /// * [String] studentId (required):
  ///
  /// * [int] limit:
  ///   Limit number of achievements returned
  Future<PlayerAchievementResponse?> getAchievementsApiV1AchievementsStudentIdGet(String studentId, { int? limit, }) async {
    final response = await getAchievementsApiV1AchievementsStudentIdGetWithHttpInfo(studentId,  limit: limit, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'PlayerAchievementResponse',) as PlayerAchievementResponse;
    
    }
    return null;
  }

  /// Get Leaderboard
  ///
  /// Get the leaderboard around the current user's XP level
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getLeaderboardApiV1AchievementsLeaderboardGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/achievements/leaderboard';

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

  /// Get Leaderboard
  ///
  /// Get the leaderboard around the current user's XP level
  Future<LeaderboardResponse?> getLeaderboardApiV1AchievementsLeaderboardGet() async {
    final response = await getLeaderboardApiV1AchievementsLeaderboardGetWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'LeaderboardResponse',) as LeaderboardResponse;
    
    }
    return null;
  }

  /// Get Xp By Days
  ///
  /// Get XP data for the current user over the last X days
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] days:
  ///   Number of days to look back
  Future<Response> getXpByDaysApiV1AchievementsXpByDaysGetWithHttpInfo({ int? days, }) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/achievements/xp_by_days';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (days != null) {
      queryParams.addAll(_queryParams('', 'days', days));
    }

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

  /// Get Xp By Days
  ///
  /// Get XP data for the current user over the last X days
  ///
  /// Parameters:
  ///
  /// * [int] days:
  ///   Number of days to look back
  Future<XpByDaysResponse?> getXpByDaysApiV1AchievementsXpByDaysGet({ int? days, }) async {
    final response = await getXpByDaysApiV1AchievementsXpByDaysGetWithHttpInfo( days: days, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'XpByDaysResponse',) as XpByDaysResponse;
    
    }
    return null;
  }
}
