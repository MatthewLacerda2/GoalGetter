//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class GoalsApi {
  GoalsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Delete Goal
  ///
  /// Delete a goal for the current student
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] goalId (required):
  Future<Response> deleteGoalApiV1GoalsGoalIdDeleteWithHttpInfo(String goalId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/goals/{goal_id}'
      .replaceAll('{goal_id}', goalId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete Goal
  ///
  /// Delete a goal for the current student
  ///
  /// Parameters:
  ///
  /// * [String] goalId (required):
  Future<void> deleteGoalApiV1GoalsGoalIdDelete(String goalId,) async {
    final response = await deleteGoalApiV1GoalsGoalIdDeleteWithHttpInfo(goalId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// List Goals
  ///
  /// List all goals for the current student, ordered by latest objective update
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> listGoalsApiV1GoalsGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/goals';

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

  /// List Goals
  ///
  /// List all goals for the current student, ordered by latest objective update
  Future<ListGoalsResponse?> listGoalsApiV1GoalsGet() async {
    final response = await listGoalsApiV1GoalsGetWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ListGoalsResponse',) as ListGoalsResponse;
    
    }
    return null;
  }

  /// Set Active Goal
  ///
  /// Set a goal as the active goal for the current student
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] goalId (required):
  Future<Response> setActiveGoalApiV1GoalsGoalIdSetActivePutWithHttpInfo(String goalId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/goals/{goal_id}/set-active'
      .replaceAll('{goal_id}', goalId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Set Active Goal
  ///
  /// Set a goal as the active goal for the current student
  ///
  /// Parameters:
  ///
  /// * [String] goalId (required):
  Future<StudentCurrentStatusResponse?> setActiveGoalApiV1GoalsGoalIdSetActivePut(String goalId,) async {
    final response = await setActiveGoalApiV1GoalsGoalIdSetActivePutWithHttpInfo(goalId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'StudentCurrentStatusResponse',) as StudentCurrentStatusResponse;
    
    }
    return null;
  }
}
