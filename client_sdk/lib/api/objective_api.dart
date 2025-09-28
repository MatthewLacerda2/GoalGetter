//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ObjectiveApi {
  ObjectiveApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get Objective
  ///
  /// Get the latest objective for the current user
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getObjectiveApiV1ObjectiveGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/objective';

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

  /// Get Objective
  ///
  /// Get the latest objective for the current user
  Future<ObjectiveResponse?> getObjectiveApiV1ObjectiveGet() async {
    final response = await getObjectiveApiV1ObjectiveGetWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ObjectiveResponse',) as ObjectiveResponse;
    
    }
    return null;
  }

  /// Get Objectives List
  ///
  /// Get all objectives for the current user's goal
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getObjectivesListApiV1ObjectiveListGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/objective/list';

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

  /// Get Objectives List
  ///
  /// Get all objectives for the current user's goal
  Future<ObjectiveListResponse?> getObjectivesListApiV1ObjectiveListGet() async {
    final response = await getObjectivesListApiV1ObjectiveListGetWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'ObjectiveListResponse',) as ObjectiveListResponse;
    
    }
    return null;
  }
}
