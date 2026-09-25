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
  static const standardQuestions = '/onboarding/about-you';

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

  // Dev-only screen index (see app/dev/dev_menu_screen.dart). Registered in the
  // router only when the app is built with --dart-define=DEV_MENU=true.
  static const dev = '/dev';
  static const devInfoScreen = '/dev/info-screen';
  static const devGoalDetail = '/dev/goal-detail';

  // The onboarding screens that need a go_router `extra` and so cannot be
  // opened by URL in a real build (#139). Each of these dev-only paths builds
  // the same screen on a fixture, which is what makes it photographable.
  static const devGoalQuestions = '/dev/goal-questions';
  static const devStudyPlan = '/dev/study-plan';
  static const devStandardQuestions = '/dev/standard-questions';
}
