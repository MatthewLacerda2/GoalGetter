import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_client.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/core/utils/provider_retry.dart';
import 'package:goal_getter/core/utils/settings_storage.dart';
import 'package:goal_getter/features/tutor/data/tutor_api.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_fake.dart';
import 'fake_tutor_api.dart';

/// The tutor over [api], its first page loaded (or failed), kept alive and
/// disposed with the test.
Future<ProviderContainer> loaded(FakeTutorApi api) async {
  SharedPreferences.setMockInitialValues({'current_goal_id': 'g1'});
  final storage = SettingsStorage(await SharedPreferences.getInstance());
  final container = ProviderContainer(
    retry: noAutomaticRetry,
    overrides: [
      tutorApiProvider.overrideWithValue(api),
      settingsStorageProvider.overrideWithValue(storage),
    ],
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
      final c = await loadedOver(ApiFake(
        {
          _listKey: [(200, '{"exchanges": []}')],
        },
        malformed: {_listKey},
      ));
      await c
          .read(tutorControllerProvider.future)
          .then<void>((_) {}, onError: (Object _) {});
      expect(c.async.error, isA<MalformedResponse>());
    });

    test('a reply that cannot be read fails the message', () async {
      final c = await loadedOver(ApiFake(
        {
          _listKey: [(200, '[]')],
          _sendKey: [(201, '{"id": 7}')],
        },
        malformed: {_sendKey},
      ));
      await c.read(tutorControllerProvider.future);

      expect(await c.tutor.send('ciao'), isA<MalformedResponse>());
      expect(c.chat.pending, const FailedMessage('ciao'));
    });

    testWidgets('a chat nobody answers ends in the error', (tester) async {
      final c = await loadedOver(
        ApiFake({}, held: {_listKey: ApiFake.never}),
      );

      await tester.pump(ApiClient.timeout + const Duration(seconds: 1));
      expect(c.async.error, isA<TimedOut>());
    });

    testWidgets('a reply nobody answers fails the message', (tester) async {
      final c = await loadedOver(ApiFake({
        _listKey: [(200, '[]')],
      }, held: {_sendKey: ApiFake.never}));
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

  group('a goal switch (#220)', () {
    String exchangeJson(String prompt) =>
        '{"id": "$prompt", "prompt": "$prompt", "responses": ["ok"],'
        ' "is_liked": false, "created_at": "2026-09-21T10:00:00.000000"}';
    String chatJson(String prompt) => '[${exchangeJson(prompt)}]';

    test("loads the new goal's chat", () async {
      final c = await loadedOver(ApiFake({
        _listKey: [(200, chatJson('on g1')), (200, chatJson('on g2'))],
      }));
      await c.read(tutorControllerProvider.future);
      expect(ids(c), ['on g1']);

      await c.read(activeGoalProvider.notifier).set('g2');
      await c.read(tutorControllerProvider.future);
      expect(ids(c), ['on g2']);
    });

    test('a reply that lands after it stays off the new chat', () async {
      final reply = Completer<void>();
      final c = await loadedOver(ApiFake({
        _listKey: [(200, chatJson('on g1')), (200, chatJson('on g2'))],
        _sendKey: [(201, exchangeJson('ciao'))],
      }, held: {_sendKey: reply.future}));
      await c.read(tutorControllerProvider.future);
      final shown = <String>[];
      c.listen(tutorControllerProvider, (_, next) {
        if (next.value case TutorChat(:final exchanges)) {
          shown.addAll(exchanges.map((e) => e.id));
        }
      });
      final sending = c.tutor.send('ciao');

      // Switched, and the reply lands before the new chat has been asked for.
      await c.read(activeGoalProvider.notifier).set('g2');
      reply.complete();
      expect(await sending, isNull, reason: 'the server took it');

      await c.read(tutorControllerProvider.future);
      expect(ids(c), ['on g2']);
      expect(c.chat.pending, isNull);
      expect(shown, isNot(contains('ciao')), reason: 'not even for a frame');
    });

    test('a reply that lands after the new chat loaded stays off it', () async {
      final reply = Completer<void>();
      final c = await loadedOver(ApiFake({
        _listKey: [(200, chatJson('on g1')), (200, chatJson('on g2'))],
        _sendKey: [(201, exchangeJson('ciao'))],
      }, held: {_sendKey: reply.future}));
      await c.read(tutorControllerProvider.future);
      final sending = c.tutor.send('ciao');

      await c.read(activeGoalProvider.notifier).set('g2');
      await c.read(tutorControllerProvider.future);
      reply.complete();
      await sending;

      expect(ids(c), ['on g2']);
    });

    test('a reply landing before the rebuild stays off every chat', () async {
      // Riverpod rebuilds a provider whose dependency changed on the next
      // frame (a zero timer here), and until then the call's ref is still
      // mounted: a reply that lands in between must not be written.
      final reply = Completer<void>();
      final api = FakeTutorApi([exchange(1)])..sendHeld = reply.future;
      final c = await loaded(api);
      final shown = <String>[];
      c.listen(tutorControllerProvider, (_, next) {
        if (next.value case TutorChat(:final exchanges)) {
          shown.addAll(exchanges.map((e) => e.id));
        }
      });
      final sending = c.tutor.send('ciao');

      await c.read(activeGoalProvider.notifier).set('g2');
      reply.complete();
      expect(await sending, isNull);
      api.stored
        ..clear()
        ..add(exchange(9)); // the new goal's chat

      await c.read(tutorControllerProvider.future);
      expect(ids(c), ['e9']);
      expect(shown, isNot(contains('new')), reason: 'not even for a frame');
    });
  });
}
