import 'package:goal_getter/app/router/app_routes.dart';

import 'golden_harness.dart';

/// The launch and the tab shell: the splash,
/// the start screen a visitor lands on, and each of the four tabs under the
/// bottom navigation bar.
void main() {
  // While GET /goals has not answered yet, with the spinner's arc drawn.
  goldenTest('splash', (tester, look) async {
    await openApp(tester, look, slow: {'GET /goals'}, settle: false);
    await tester.pump(const Duration(milliseconds: 400));
  });

  goldenTest('start', (tester, look) async {
    await openApp(tester, look, signedIn: false);
  });

  for (final (name, path) in [
    ('home', AppRoutes.home),
    ('tutor', AppRoutes.tutor),
    ('resources', AppRoutes.resources),
    ('profile', AppRoutes.profile),
  ]) {
    goldenTest(name, (tester, look) => openAt(tester, look, path));
  }
}
