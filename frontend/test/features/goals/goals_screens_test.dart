import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/screens/goal_detail_screen.dart';
import 'package:goal_getter/features/goals/presentation/screens/goals_list_screen.dart';

import '../fake_backend.dart';

final _routes = [
  GoRoute(path: '/goals', builder: (_, __) => const GoalsListScreen()),
  GoRoute(
    path: '/goals/:id',
    builder: (_, state) => GoalDetailScreen(
      goalId: state.pathParameters['id']!,
      goal: state.extra as Goal?,
    ),
  ),
];

Future<FakeBackend> open(
  WidgetTester tester,
  Map<String, List<Reply>> replies, {
  String at = '/goals',
}) async {
  final backend = FakeBackend(replies);
  await backend.start({'current_goal_id': 'g1'});
  await pumpRouted(tester, backend, _routes, initial: at);
  return backend;
}

final _twoGoals = [
  (200, '[${goalJson('g1', active: true)}, ${goalJson('g2', name: 'Chess')}]'),
];

void main() {
  testWidgets('the list shows each goal, and a tap opens the detail',
      (tester) async {
    final backend = await open(tester, {'GET /goals': _twoGoals});

    expect(find.text('Chess'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Elo 1100'), findsNWidgets(2));
    // Neither the card nor the detail dates a goal.
    expect(find.textContaining('Created'), findsNothing);
    expect(find.textContaining('Sep 1, 2026'), findsNothing);

    await tester.tap(find.text('Chess'));
    await tester.pumpAndSettle();

    expect(find.text('Set as current goal'), findsOneWidget);
    expect(find.textContaining('Updated'), findsNothing);
    expect(find.textContaining('Sep 20, 2026'), findsNothing);
    expect(backend.calls, ['GET /goals'], reason: 'the detail never fetches');
  });

  testWidgets('the create button opens goal creation', (tester) async {
    await open(tester, {'GET /goals': _twoGoals});

    await tester.tap(find.text('Create new goal'));
    await tester.pumpAndSettle();

    expect(find.text('landed /onboarding/goal'), findsOneWidget);
  });

  // With no goals the empty state's own action is the way in; the floating
  // button would say the same thing twice.
  testWidgets('an empty list offers only the first-goal action',
      (tester) async {
    await open(tester, {'GET /goals': [(200, '[]')]});

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Create new goal'), findsNothing);

    await tester.tap(find.text('Create first goal'));
    await tester.pumpAndSettle();

    expect(find.text('landed /onboarding/goal'), findsOneWidget);
  });

  testWidgets('a failed load shows the error and a retry that reloads',
      (tester) async {
    await open(tester, {
      'GET /goals': [(500, '{"detail": "Database down"}'), ..._twoGoals],
    });

    expect(find.text('Could not load your goals'), findsOneWidget);
    expect(find.text('Database down'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Chess'), findsOneWidget);
  });

  testWidgets('set as active lands on home', (tester) async {
    await open(tester, {
      'GET /goals': _twoGoals,
      'PUT /goals/g2/set-active': [(200, '{"goal_id": "g2"}')],
    }, at: '/goals/g2');

    await tester.tap(find.text('Set as current goal'));
    await tester.pumpAndSettle();

    expect(find.text('landed /home'), findsOneWidget);
  });

  // An action that failed is a snackbar over the screen the student is still
  // on, so the goal and its buttons stay where they were (#98).
  testWidgets('a failed set-active is a snackbar over the detail',
      (tester) async {
    await open(tester, {
      'GET /goals': _twoGoals,
      'PUT /goals/g2/set-active': [(404, '{"detail": "Goal not found"}')],
    }, at: '/goals/g2');

    await tester.tap(find.text('Set as current goal'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Could not make this your active goal'), findsOneWidget);
    expect(find.text('Goal not found'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Set as current goal'), findsOneWidget);
  });

  testWidgets('delete asks first, then lands on the list', (tester) async {
    final backend = await open(tester, {
      'GET /goals': _twoGoals,
      'DELETE /goals/g1': [(204, '')],
    }, at: '/goals/g1');

    await tester.tap(find.text('Delete Goal?'));
    await tester.pumpAndSettle();
    expect(backend.calls, isNot(contains('DELETE /goals/g1')));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(backend.calls, contains('DELETE /goals/g1'));
    expect(backend.storage.readCurrentGoalId(), isNull);
    expect(find.byType(GoalsListScreen), findsOneWidget);
  });
}
