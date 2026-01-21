import 'package:openapi/api.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

/// Small helper to build an authorized OpenAPI [ApiClient] for this project.
///
/// Default behavior matches the existing call sites:
/// - Prefer stored JWT access token
/// - Fall back to stored Google token
/// - Throw if no token is available
class OpenApiClientFactory {
  OpenApiClientFactory({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<ApiClient> createAuthorized() async {
    final accessToken = await _authService.getStoredAccessToken();
    final googleToken = await _authService.getStoredGoogleToken();
    final authToken = accessToken ?? googleToken;

    if (authToken == null || authToken.isEmpty) {
      throw Exception('No authentication token available');
    }

    final apiClient = ApiClient(basePath: AppConfig.baseUrl);
    apiClient.addDefaultHeader('Authorization', 'Bearer $authToken');
    return apiClient;
  }

  Future<ApiClient> createWithAccessToken() async {
    final accessToken = await _authService.getStoredAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token available. Please sign in again.');
    }

    final apiClient = ApiClient(basePath: AppConfig.baseUrl);
    apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');
    return apiClient;
  }

  Future<ApiClient> createWithGoogleToken() async {
    final googleToken = await _authService.getStoredGoogleToken();
    if (googleToken == null || googleToken.isEmpty) {
      throw Exception('No Google token available. Please sign in again.');
    }

    final apiClient = ApiClient(basePath: AppConfig.baseUrl);
    apiClient.addDefaultHeader('Authorization', 'Bearer $googleToken');
    return apiClient;
  }
}
