//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class RoadmapApi {
  RoadmapApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create Roadmap
  ///
  /// Create a roadmap based on the user's goal and follow-up questions.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RoadmapCreationRequest] roadmapCreationRequest (required):
  Future<Response> createRoadmapApiV1RoadmapCreationPostWithHttpInfo(RoadmapCreationRequest roadmapCreationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/roadmap/creation';

    // ignore: prefer_final_locals
    Object? postBody = roadmapCreationRequest;

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

  /// Create Roadmap
  ///
  /// Create a roadmap based on the user's goal and follow-up questions.
  ///
  /// Parameters:
  ///
  /// * [RoadmapCreationRequest] roadmapCreationRequest (required):
  Future<RoadmapCreationResponse?> createRoadmapApiV1RoadmapCreationPost(RoadmapCreationRequest roadmapCreationRequest,) async {
    final response = await createRoadmapApiV1RoadmapCreationPostWithHttpInfo(roadmapCreationRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RoadmapCreationResponse',) as RoadmapCreationResponse;
    
    }
    return null;
  }

  /// Initiate Roadmap
  ///
  /// Initiate the roadmap creation process by analyzing the user's goal prompt and generating follow-up questions.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [RoadmapInitiationRequest] roadmapInitiationRequest (required):
  Future<Response> initiateRoadmapApiV1RoadmapInitiationPostWithHttpInfo(RoadmapInitiationRequest roadmapInitiationRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/roadmap/initiation';

    // ignore: prefer_final_locals
    Object? postBody = roadmapInitiationRequest;

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

  /// Initiate Roadmap
  ///
  /// Initiate the roadmap creation process by analyzing the user's goal prompt and generating follow-up questions.
  ///
  /// Parameters:
  ///
  /// * [RoadmapInitiationRequest] roadmapInitiationRequest (required):
  Future<RoadmapInitiationResponse?> initiateRoadmapApiV1RoadmapInitiationPost(RoadmapInitiationRequest roadmapInitiationRequest,) async {
    final response = await initiateRoadmapApiV1RoadmapInitiationPostWithHttpInfo(roadmapInitiationRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'RoadmapInitiationResponse',) as RoadmapInitiationResponse;
    
    }
    return null;
  }
}
