import 'package:goal_getter/app/router/app_routes.dart';

import 'golden_harness.dart';
import 'student.dart';

/// Goal creation, each step on the route the app takes to it, the ones that
/// need an `extra` handed the student's own.
void main() {
  goldenTest(
    'goal_prompt',
    (tester, look) => openAt(tester, look, AppRoutes.goalPrompt),
  );

  goldenTest(
    'goal_questions',
    (tester, look) => openAt(
      tester,
      look,
      AppRoutes.goalQuestions,
      extra: goalQuestions,
      signedIn: false,
    ),
  );

  goldenTest(
    'study_plan',
    (tester, look) => openAt(
      tester,
      look,
      AppRoutes.studyPlan,
      extra: goalDraft,
      signedIn: false,
    ),
  );

  goldenTest(
    'standard_questions',
    (tester, look) => openAt(
      tester,
      look,
      AppRoutes.standardQuestions,
      extra: standardQuestions,
    ),
  );
}
