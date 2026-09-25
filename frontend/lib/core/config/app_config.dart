class AppConfig {
  /// Where the backend answers, without a trailing slash. Empty (the default)
  /// means the page's own origin on web, which is how production is served:
  /// nginx proxies `/api` next to the bundle. See `resolveBaseUrl` in
  /// core/api/api_client.dart.
  static const String baseUrl = String.fromEnvironment('BASE_URL');

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '330000594920-iuok5ott835b3bb983e6dao0fanrrnmr.apps.googleusercontent.com',
  );

  /// Dev-only: show the all-screens index (app/dev/dev_menu_screen.dart) at
  /// startup instead of the normal auth/onboarding splash. Off unless the build
  /// passes --dart-define=DEV_MENU=true, so production is unaffected.
  static const bool devMenu = bool.fromEnvironment('DEV_MENU');

  /// Dev-only: the start screen offers "continue as a fictitious user", which
  /// signs in through POST /auth/dev-login instead of Google. Off unless the
  /// build passes --dart-define=DEV_LOGIN=true; the backend must run with
  /// DEV_LOGIN=true too, or the route is a 404.
  static const bool devLogin = bool.fromEnvironment('DEV_LOGIN');

  /// The name sent to /auth/dev-login; the backend stores it as
  /// `Fictitious <name>`. Defaults to Claude's own fictitious student, so the
  /// app and `make claude-token` see the same data.
  static const String devLoginName =
      String.fromEnvironment('DEV_LOGIN_NAME', defaultValue: 'Claude');
}
