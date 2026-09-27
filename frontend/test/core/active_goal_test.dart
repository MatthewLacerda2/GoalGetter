import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/core/services/session.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/goals/presentation/controllers/goals_list_controller.dart';

import '../features/fake_backend.dart';

/// The app's one copy of the server's active goal (#220).

Future<(ProviderContainer, FakeBackend)> _over(
  Map<String, List<Reply>> replies,
) async {
  final backend = FakeBackend(replies);
  await backend.start({'current_goal_id': 'g1'});
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: backend.overrides,
  );
  addTearDown(container.dispose);
  return (container, backend);
}

void main() {
  test('starts from what the device stored', () async {
    final (c, _) = await _over({});
    expect(c.read(activeGoalProvider), 'g1');
  });

  test('every GET /goals moves it to the goal the server marks', () async {
    final (c, backend) = await _over({
      'GET /goals': [(200, '[${goalJson('g1')}, ${goalJson('g2', active: true)}]')],
    });
    await c.read(goalsListControllerProvider.future);

    expect(c.read(activeGoalProvider), 'g2');
    expect(backend.storage.readCurrentGoalId(), 'g2');
  });

  test("a new session does not inherit the last one's goal", () async {
    final (c, backend) = await _over({});
    c.listen(activeGoalProvider, (_, __) {});
    await backend.storage.clearAll(); // signed out
    c.read(signedInProvider.notifier).sync();
    await backend.storage.setAccessToken('another student');
    c.read(signedInProvider.notifier).sync();

    expect(c.read(activeGoalProvider), isNull);
  });
}
