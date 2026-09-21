import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/features/goals/data/goals_api.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goal_actions.dart';

import '../fake_backend.dart';

Goal goal(String id, {bool active = false}) => Goal(
      id: id,
      name: id,
      description: '',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      currentElo: 1000,
      isActive: active,
    );

/// Actions against [backend], with g1 stored as the active goal.
Future<GoalActions> actions(FakeBackend backend) async {
  await backend.start({'current_goal_id': 'g1'});
  final api = GoalsApi(backend.api);
  backend.calls.clear();
  return GoalActions(
    api: api,
    storage: backend.storage,
    reloadGoals: api.list,
  );
}

void main() {
  test('set-active calls the endpoint, stores the id, lands home', () async {
    final backend = FakeBackend({
      'PUT /goals/g2/set-active': [(200, '{"goal_id": "g2"}')],
      'GET /goals': [(200, '[${goalJson('g2', active: true)}]')],
    });
    final landing = await (await actions(backend)).setActive(goal('g2'));

    expect(backend.calls.first, 'PUT /goals/g2/set-active');
    expect(backend.storage.readCurrentGoalId(), 'g2');
    expect(landing, '/home');
  });

  test('deleting the active goal clears the stored id, lands on the list',
      () async {
    final backend = FakeBackend({
      'DELETE /goals/g1': [(204, '')],
      'GET /goals': [(200, '[${goalJson('g2')}]')],
    });
    final landing =
        await (await actions(backend)).delete(goal('g1', active: true));

    expect(backend.storage.readCurrentGoalId(), isNull);
    expect(landing, '/goals');
  });

  test('deleting the last goal lands on goal creation', () async {
    final backend = FakeBackend({
      'DELETE /goals/g1': [(204, '')],
      'GET /goals': [(200, '[]')],
    });
    final landing =
        await (await actions(backend)).delete(goal('g1', active: true));

    expect(landing, '/onboarding/goal');
  });

  test('deleting another goal keeps the active one', () async {
    final backend = FakeBackend({
      'DELETE /goals/g2': [(204, '')],
      'GET /goals': [(200, '[${goalJson('g1', active: true)}]')],
    });
    final landing = await (await actions(backend)).delete(goal('g2'));

    expect(backend.storage.readCurrentGoalId(), 'g1');
    expect(landing, '/goals');
  });

  test('a failed delete throws and changes nothing locally', () async {
    final backend = FakeBackend({
      'DELETE /goals/g1': [(404, '{"detail": "Goal not found"}')],
    });
    final pending = (await actions(backend)).delete(goal('g1', active: true));

    await expectLater(pending, throwsA(isA<ApiException>()));
    expect(backend.storage.readCurrentGoalId(), 'g1');
  });
}
