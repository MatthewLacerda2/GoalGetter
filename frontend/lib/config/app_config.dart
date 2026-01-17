class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    // No trailing slash here is usually safer if your SDK adds the leading slash
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
