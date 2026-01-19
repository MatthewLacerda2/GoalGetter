//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class StudentContextApi {
  StudentContextApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create Student Context
  ///
  /// Create a new student context
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateStudentContextRequest] createStudentContextRequest (required):
  Future<Response> createStudentContextApiV1StudentContextPostWithHttpInfo(CreateStudentContextRequest createStudentContextRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/student-context';

    // ignore: prefer_final_locals
    Object? postBody = createStudentContextRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create Student Context
  ///
  /// Create a new student context
  ///
  /// Parameters:
  ///
  /// * [CreateStudentContextRequest] createStudentContextRequest (required):
  Future<StudentContextItem?> createStudentContextApiV1StudentContextPost(CreateStudentContextRequest createStudentContextRequest,) async {
    final response = await createStudentContextApiV1StudentContextPostWithHttpInfo(createStudentContextRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'StudentContextItem',) as StudentContextItem;
    
    }
    return null;
  }

  /// Delete Student Context
  ///
  /// Delete a student context
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] contextId (required):
  Future<Response> deleteStudentContextApiV1StudentContextContextIdDeleteWithHttpInfo(String contextId,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/student-context/{context_id}'
      .replaceAll('{context_id}', contextId);

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

  /// Delete Student Context
  ///
  /// Delete a student context
  ///
  /// Parameters:
  ///
  /// * [String] contextId (required):
  Future<void> deleteStudentContextApiV1StudentContextContextIdDelete(String contextId,) async {
    final response = await deleteStudentContextApiV1StudentContextContextIdDeleteWithHttpInfo(contextId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get Student Contexts
  ///
  /// Get student contexts for the current user's objective
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getStudentContextsApiV1StudentContextGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/student-context';

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

  /// Get Student Contexts
  ///
  /// Get student contexts for the current user's objective
  Future<StudentContextResponse?> getStudentContextsApiV1StudentContextGet() async {
    final response = await getStudentContextsApiV1StudentContextGetWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'StudentContextResponse',) as StudentContextResponse;
    
    }
    return null;
  }
}
