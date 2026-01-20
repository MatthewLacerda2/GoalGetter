//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class AuthApi {
  AuthApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Delete Account
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> deleteAccountApiV1AuthAccountDeleteWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/account';

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

  /// Delete Account
  Future<void> deleteAccountApiV1AuthAccountDelete() async {
    final response = await deleteAccountApiV1AuthAccountDeleteWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Login
  ///
  /// Login using Google OAuth2 token.
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [OAuth2Request] oAuth2Request (required):
  Future<Response> loginApiV1AuthLoginPostWithHttpInfo(OAuth2Request oAuth2Request,) async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/login';

    // ignore: prefer_final_locals
    Object? postBody = oAuth2Request;

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

  /// Login
  ///
  /// Login using Google OAuth2 token.
  ///
  /// Parameters:
  ///
  /// * [OAuth2Request] oAuth2Request (required):
  Future<TokenResponse?> loginApiV1AuthLoginPost(OAuth2Request oAuth2Request,) async {
    final response = await loginApiV1AuthLoginPostWithHttpInfo(oAuth2Request,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TokenResponse',) as TokenResponse;
    
    }
    return null;
  }

  /// Signup
  ///
  /// Sign up or sign in using Google OAuth2 token. Creates a new account if the user doesn't exist, or returns existing account info.
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> signupApiV1AuthSignupPostWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/api/v1/auth/signup';

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

  /// Signup
  ///
  /// Sign up or sign in using Google OAuth2 token. Creates a new account if the user doesn't exist, or returns existing account info.
  Future<TokenResponse?> signupApiV1AuthSignupPost() async {
    final response = await signupApiV1AuthSignupPostWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'TokenResponse',) as TokenResponse;
    
    }
    return null;
  }
}
