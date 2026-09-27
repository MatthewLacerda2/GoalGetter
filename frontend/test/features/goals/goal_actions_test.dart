import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/goals/domain/goal.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goal_actions.dart';

import '../fake_backend.dart';

Goal goal(String id, {bool active = false}) => Goal(
      id: id,
      name: id,
      description: '',
      currentElo: 1000,
      isActive: active,
    );

late ProviderContainer _container;

/// Actions against [backend], with g1 stored as the active goal.
Future<GoalActions> actions(FakeBackend backend) async {
  await backend.start({'current_goal_id': 'g1'});
  _container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: backend.overrides,
  );
  addTearDown(_container.dispose);
  backend.calls.clear();
  return _container.read(goalActionsProvider);
}

/// The active goal as the app holds it, and as the device stores it.
(String?, String?) held(FakeBackend backend) =>
    (_container.read(activeGoalProvider), backend.storage.readCurrentGoalId());

void main() {
  test('set-active calls the endpoint, stores the id, lands home', () async {
    final backend = FakeBackend({
      'PUT /goals/g2/set-active': [(200, '{"goal_id": "g2"}')],
      'GET /goals': [(200, '[${goalJson('g2', active: true)}]')],
    });
    final landing = await (await actions(backend)).setActive(goal('g2'));

    expect(backend.calls.first, 'PUT /goals/g2/set-active');
    expect(held(backend), ('g2', 'g2'));
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

    expect(held(backend), (null, null));
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

    expect(held(backend), ('g1', 'g1'));
    expect(landing, '/goals');
  });

  test('a failed delete throws and changes nothing locally', () async {
    final backend = FakeBackend({
      'DELETE /goals/g1': [(404, '{"detail": "Goal not found"}')],
    });
    final pending = (await actions(backend)).delete(goal('g1', active: true));

    await expectLater(pending, throwsA(isA<ApiException>()));
    expect(held(backend), ('g1', 'g1'));
  });
}
