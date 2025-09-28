//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ActivitiesApi {
  ActivitiesApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Take Multiple Choice Activity
  ///
  /// Takes the student's answers and informs the accuracy
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MultipleChoiceActivityEvaluationRequest] multipleChoiceActivityEvaluationRequest (required):
  Future<Response> takeMultipleChoiceActivityApiV1ActivitiesEvaluatePostWithHttpInfo(MultipleChoiceActivityEvaluationRequest multipleChoiceActivityEvaluationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/activities/evaluate';

    // ignore: prefer_final_locals
    Object? postBody = multipleChoiceActivityEvaluationRequest;

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

  /// Take Multiple Choice Activity
  ///
  /// Takes the student's answers and informs the accuracy
  ///
  /// Parameters:
  ///
  /// * [MultipleChoiceActivityEvaluationRequest] multipleChoiceActivityEvaluationRequest (required):
  Future<MultipleChoiceActivityEvaluationResponse?> takeMultipleChoiceActivityApiV1ActivitiesEvaluatePost(MultipleChoiceActivityEvaluationRequest multipleChoiceActivityEvaluationRequest,) async {
    final response = await takeMultipleChoiceActivityApiV1ActivitiesEvaluatePostWithHttpInfo(multipleChoiceActivityEvaluationRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MultipleChoiceActivityEvaluationResponse',) as MultipleChoiceActivityEvaluationResponse;
    
    }
    return null;
  }

  /// Take Multiple Choice Activity
  ///
  /// Deliver a multiple choice activity to the current user.  It takes one from the DB or creates a new activity for the user if none exists.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> takeMultipleChoiceActivityApiV1ActivitiesPostWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/activities';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


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

  /// Take Multiple Choice Activity
  ///
  /// Deliver a multiple choice activity to the current user.  It takes one from the DB or creates a new activity for the user if none exists.
  Future<MultipleChoiceActivityResponse?> takeMultipleChoiceActivityApiV1ActivitiesPost() async {
    final response = await takeMultipleChoiceActivityApiV1ActivitiesPostWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'MultipleChoiceActivityResponse',) as MultipleChoiceActivityResponse;
    
    }
    return null;
  }
}
