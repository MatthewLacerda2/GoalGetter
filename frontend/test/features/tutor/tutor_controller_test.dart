import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/features/tutor/data/tutor_api.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_controller.dart';

import '../api_fake.dart';
import 'fake_tutor_api.dart';

/// The tutor over [api], its first page loaded (or failed), kept alive and
/// disposed with the test.
Future<ProviderContainer> loaded(FakeTutorApi api) async {
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [tutorApiProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  container.listen(tutorControllerProvider, (_, __) {});
  // A failed load is read back from the provider's AsyncError.
  await container
      .read(tutorControllerProvider.future)
      .then<void>((_) {}, onError: (Object _) {});
  return container;
}

/// The tutor over the real [TutorApi], on [fake]'s backend.
Future<ProviderContainer> loadedOver(ApiFake fake) async {
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: await fake.overrides(),
  );
  addTearDown(container.dispose);
  container.listen(tutorControllerProvider, (_, __) {});
  return container;
}

const _listKey = 'GET /tutor/messages';
const _sendKey = 'POST /tutor/messages';

extension on ProviderContainer {
  TutorController get tutor => read(tutorControllerProvider.notifier);

  AsyncValue<TutorState> get async => read(tutorControllerProvider);

  TutorChat get chat => async.value! as TutorChat;
}

List<String> ids(ProviderContainer c) => [
  for (final e in c.chat.exchanges) e.id,
];

void main() {
  test(
    'the first page is the newest 20, oldest first, with more to come',
    () async {
      final c = await loaded(
        FakeTutorApi([for (var i = 1; i <= 25; i++) exchange(i)]),
      );
      expect(ids(c), [for (var i = 6; i <= 25; i++) 'e$i']);
      expect(c.chat.older, const MoreOlderPages());
    },
  );

  test(
    'older pages ask before the oldest loaded exchange, and prepend',
    () async {
      final api = FakeTutorApi([for (var i = 1; i <= 25; i++) exchange(i)]);
      final c = await loaded(api);
      await c.tutor.loadOlder();
      expect(api.beforeCalls.last, exchange(6).createdAt);
      expect(ids(c), [for (var i = 1; i <= 25; i++) 'e$i']);
      expect(c.chat.older, const NoOlderPages());
    },
  );

  test('no active goal is its own state, not an error', () async {
    final api = FakeTutorApi([])
      ..listError = const ApiException(404, TutorApi.noActiveGoal);
    final c = await loaded(api);
    expect(c.async.value, const TutorNoActiveGoal());
  });

  test('a failed load is an error, and retrying loads the page', () async {
    final api = FakeTutorApi([exchange(1)])..listError = geminiDown;
    final c = await loaded(api);
    expect(c.async.error, same(geminiDown));
    api.listError = null;
    c.invalidate(tutorControllerProvider);
    await c.read(tutorControllerProvider.future);
    expect(ids(c), ['e1']);
  });

  test('a sent message appends the stored exchange', () async {
    final c = await loaded(FakeTutorApi([exchange(1)]));
    expect(await c.tutor.send('  ciao  '), isNull);
    expect(ids(c), ['e1', 'new']);
    expect(c.chat.exchanges.last.prompt, 'ciao');
    expect(c.chat.pending, isNull);
  });

  test('a failed send keeps the text and hands back the reason', () async {
    final c = await loaded(FakeTutorApi([])..sendError = geminiDown);
    expect(await c.tutor.send('ciao'), same(geminiDown));
    expect(c.chat.pending, const FailedMessage('ciao'));
    expect(c.chat.isSending, isFalse);
  });

  test('a like is set, and put back when the backend refuses it', () async {
    final api = FakeTutorApi([exchange(1)]);
    final c = await loaded(api);
    expect(await c.tutor.setLike('e1', true), isNull);
    expect(c.chat.exchanges.single.isLiked, isTrue);
    api.likeError = geminiDown;
    expect(await c.tutor.setLike('e1', false), same(geminiDown));
    expect(c.chat.exchanges.single.isLiked, isTrue);
  });

  test('a failed older page waits for an explicit retry', () async {
    final api = FakeTutorApi([for (var i = 1; i <= 25; i++) exchange(i)]);
    final c = await loaded(api);
    api.listError = geminiDown;
    await c.tutor.loadOlder();
    expect(c.chat.older, const OlderPagesFailed(geminiDown));

    api.listError = null;
    await c.tutor.loadOlder(); // scrolling does not try again
    expect(api.beforeCalls, hasLength(2));
    await c.tutor.loadOlder(retry: true);
    expect(ids(c), hasLength(25));
  });

  test('a tutor left mid-send drops the reply quietly', () async {
    final c = await loaded(FakeTutorApi([]));
    final sending = c.tutor.send('ciao');
    c.dispose(); // the student left the tutor
    await expectLater(sending, completion(isNull));
  });

  group('an answer the app cannot read, or none at all (#221)', () {
    test('a chat that cannot be read is the error', () async {
      final c = await loadedOver(ApiFake({
        _listKey: [(200, '{"exchanges": []}')],
      }));
      await c
          .read(tutorControllerProvider.future)
          .then<void>((_) {}, onError: (Object _) {});
      expect(c.async.error, isA<MalformedResponse>());
    });

    test('a reply that cannot be read fails the message', () async {
      final c = await loadedOver(ApiFake({
        _listKey: [(200, '[]')],
        _sendKey: [(201, '{"id": 7}')],
      }));
      await c.read(tutorControllerProvider.future);

      expect(await c.tutor.send('ciao'), isA<MalformedResponse>());
      expect(c.chat.pending, const FailedMessage('ciao'));
    });

    testWidgets('a chat nobody answers ends in the error', (tester) async {
      final c = await loadedOver(ApiFake({}, silent: {_listKey}));

      await tester.pump(ApiClient.timeout + const Duration(seconds: 1));
      expect(c.async.error, isA<TimedOut>());
    });

    testWidgets('a reply nobody answers fails the message', (tester) async {
      final c = await loadedOver(ApiFake({
        _listKey: [(200, '[]')],
      }, silent: {_sendKey}));
      await tester.pump();
      Object? failure;
      unawaited(c.tutor.send('ciao').then((e) => failure = e));
      await tester.pump();
      expect(c.chat.pending, const SendingMessage('ciao'));

      await tester.pump(ApiClient.timeout + const Duration(seconds: 1));
      expect(failure, isA<TimedOut>());
      expect(c.chat.pending, const FailedMessage('ciao'));
    });
  });
}
