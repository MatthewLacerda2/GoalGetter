/// Centralized route paths for the app's go_router configuration.
///
/// Single source of truth for navigation locations. Use these constants with
/// `context.go(...)` / `context.push(...)` rather than hardcoding path strings.
class AppRoutes {
  AppRoutes._();

  /// Startup splash that resolves auth/onboarding state and redirects.
  static const splash = '/';

  // Onboarding / auth
  static const start = '/start';
  static const goalPrompt = '/onboarding/goal';
  static const goalQuestions = '/onboarding/questions';
  static const studyPlan = '/onboarding/plan';

  // Bottom-nav shell tabs
  static const home = '/home';
  static const tutor = '/tutor';
  static const resources = '/resources';
  static const profile = '/profile';

  // Lesson flow
  static const lesson = '/lesson';
  static const lessonFinish = '/lesson/finish';

  // Goals management
  static const goals = '/goals';
  static String goalDetail(String id) => '/goals/$id';
}
