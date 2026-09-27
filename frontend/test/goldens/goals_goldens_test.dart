import 'package:goal_getter/app/router/app_routes.dart';

import 'golden_harness.dart';

/// The goals list, and one goal opened by its URL — the detail screen on its
/// own, fetching the goal rather than handed it by the list.
void main() {
  goldenTest('goals', (tester, look) => openAt(tester, look, AppRoutes.goals));

  goldenTest(
    'goal_detail',
    (tester, look) => openAt(tester, look, AppRoutes.goalDetail('g1')),
  );
}
