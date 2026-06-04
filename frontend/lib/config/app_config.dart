class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    // No trailing slash here is usually safer if your SDK adds the leading slash
    //defaultValue: 'https://goalsgetter.org',
    defaultValue: 'http://192.168.0.9:8000',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '330000594920-iuok5ott835b3bb983e6dao0fanrrnmr.apps.googleusercontent.com',
  );
}
