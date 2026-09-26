import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/tutor/data/tutor_api.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_controller.dart';

import 'fake_tutor_api.dart';

/// A controller over [api], with its first page loaded.
Future<TutorController> loaded(FakeTutorApi api) async {
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [tutorApiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  container.listen(tutorControllerProvider, (_, __) {});
  final controller = container.read(tutorControllerProvider.notifier);
  await controller.load();
  return controller;
}

List<String> ids(TutorController c) => [
  for (final e in c.state.exchanges) e.id,
];

void main() {
  test(
    'the first page is the newest 20, oldest first, with more to come',
    () async {
      final c = await loaded(
        FakeTutorApi([for (var i = 1; i <= 25; i++) exchange(i)]),
      );
      expect(ids(c), [for (var i = 6; i <= 25; i++) 'e$i']);
      expect(c.state.hasMore, isTrue);
    },
  );

  test(
    'older pages ask before the oldest loaded exchange, and prepend',
    () async {
      final api = FakeTutorApi([for (var i = 1; i <= 25; i++) exchange(i)]);
      final c = await loaded(api);
      await c.loadOlder();
      expect(api.beforeCalls.last, exchange(6).createdAt);
      expect(ids(c), [for (var i = 1; i <= 25; i++) 'e$i']);
      expect(c.state.hasMore, isFalse);
    },
  );

  test('no active goal is its own state, not an error', () async {
    final api = FakeTutorApi([])
      ..listError = const ApiException(404, TutorApi.noActiveGoal);
    final c = await loaded(api);
    expect(c.state.load, TutorLoad.noActiveGoal);
  });

  test('a failed load is an error, and retrying loads the page', () async {
    final api = FakeTutorApi([exchange(1)])..listError = geminiDown;
    final c = await loaded(api);
    expect(c.state.load, TutorLoad.failed);
    api.listError = null;
    await c.load();
    expect(ids(c), ['e1']);
  });

  test('a sent message appends the stored exchange', () async {
    final c = await loaded(FakeTutorApi([exchange(1)]));
    expect(await c.send('  ciao  '), isNull);
    expect(ids(c), ['e1', 'new']);
    expect(c.state.exchanges.last.prompt, 'ciao');
    expect(c.state.pending, isNull);
  });

  test('a failed send keeps the text and hands back the reason', () async {
    final c = await loaded(FakeTutorApi([])..sendError = geminiDown);
    expect(await c.send('ciao'), same(geminiDown));
    expect(c.state.pending?.text, 'ciao');
    expect(c.state.pending?.failed, isTrue);
    expect(c.state.isSending, isFalse);
  });

  test('a like is set, and put back when the backend refuses it', () async {
    final api = FakeTutorApi([exchange(1)]);
    final c = await loaded(api);
    expect(await c.setLike('e1', true), isNull);
    expect(c.state.exchanges.single.isLiked, isTrue);
    api.likeError = geminiDown;
    expect(await c.setLike('e1', false), same(geminiDown));
    expect(c.state.exchanges.single.isLiked, isTrue);
  });
}
