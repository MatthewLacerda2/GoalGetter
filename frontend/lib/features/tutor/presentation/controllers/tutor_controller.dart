import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/core/services/active_goal.dart';
import 'package:goal_getter/features/tutor/data/tutor_api.dart';
import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:goal_getter/features/tutor/presentation/controllers/tutor_state.dart';

part 'tutor_controller.g.dart';

/// The chat with the tutor on the active goal. [build] loads its newest page,
/// again whenever the active goal changes (#220); `ref.invalidate` loads it
/// again too - the retry after a failed load.
///
/// Every call made after the first page drops its answer once the chat it
/// started on is gone ([_stillCurrent]).
@riverpod
class TutorController extends _$TutorController {
  /// The active goal the chat on screen was loaded for.
  String? _goal;

  @override
  Future<TutorState> build() async {
    // The backend scopes the chat to the active goal on its own; watching it
    // is what loads the new goal's chat when the student switches.
    _goal = ref.watch(activeGoalProvider);
    try {
      final page = await ref.read(tutorApiProvider).list();
      return TutorChat(
        exchanges: page.reversed.toList(),
        older: _olderThan(page),
      );
    } on ApiException catch (e) {
      if (e.code == ErrorCode.noActiveGoal) {
        return const TutorNoActiveGoal();
      }
      rethrow;
    }
  }

  /// A full page means there may be more before it.
  static OlderPages _olderThan(List<ChatExchange> page) =>
      page.length == TutorApi.pageSize
      ? const MoreOlderPages()
      : const NoOlderPages();

  /// The chat on screen, when there is one.
  TutorChat? get _chat => switch (state) {
    AsyncData(value: final TutorChat chat) => chat,
    _ => null,
  };

  /// For a call starting now: whether its answer still belongs on screen.
  ///
  /// Not once the provider was disposed or rebuilt — its ref is unmounted
  /// then. Nor once the active goal changed: Riverpod rebuilds on the next
  /// frame, and until then the ref is still mounted, so a reply landing in
  /// that gap would be written onto the old goal's chat — and a write there
  /// cancels the rebuild, leaving the old chat on screen (#220, measured).
  bool Function() _stillCurrent() {
    final opened = ref;
    final goal = _goal;
    return () => opened.mounted && opened.read(activeGoalProvider) == goal;
  }

  /// Applies [change] to the chat on screen, when there still is one.
  void _update(TutorChat Function(TutorChat) change) {
    final chat = _chat;
    if (chat != null) state = AsyncData(change(chat));
  }

  /// Loads the page before the oldest loaded exchange. After a failure only
  /// an explicit [retry] tries again, so scrolling does not hammer the server.
  Future<void> loadOlder({bool retry = false}) async {
    final chat = _chat;
    final canLoad = switch (chat?.older) {
      MoreOlderPages() => true,
      OlderPagesFailed() => retry,
      _ => false,
    };
    if (chat == null || !canLoad) return;
    state = AsyncData(chat.withOlder(const LoadingOlderPages()));
    final current = _stillCurrent();
    try {
      final page = await ref
          .read(tutorApiProvider)
          .list(before: chat.exchanges.first.createdAt);
      if (!current()) return;
      _update(
        (c) => c
            .withExchanges([...page.reversed, ...c.exchanges])
            .withOlder(_olderThan(page)),
      );
    } on Exception catch (e) {
      if (current()) _update((c) => c.withOlder(OlderPagesFailed(e)));
    }
  }

  /// Sends [text], shown at once as a pending bubble. Returns what the call
  /// threw, or null when it went through: the bubble stays, marked failed, and
  /// the caller gives the text back to the student and says why.
  Future<Object?> send(String text) async {
    final message = text.trim();
    final chat = _chat;
    if (message.isEmpty || chat == null || chat.isSending) return null;
    state = AsyncData(chat.withPending(SendingMessage(message)));
    final current = _stillCurrent();
    try {
      final exchange = await ref.read(tutorApiProvider).send(message);
      if (current()) {
        _update(
          (c) => c.withExchanges([...c.exchanges, exchange]).withPending(null),
        );
      }
      return null;
    } on Exception catch (e) {
      if (current()) _update((c) => c.withPending(FailedMessage(message)));
      return e;
    }
  }

  /// Sets the like at once, then confirms it with the backend. Returns what
  /// the backend threw, with the like put back, or null when it was saved.
  Future<Object?> setLike(String exchangeId, bool isLiked) async {
    _replace(exchangeId, (e) => e.copyWith(isLiked: isLiked));
    final current = _stillCurrent();
    try {
      final saved = await ref
          .read(tutorApiProvider)
          .setLike(exchangeId, isLiked);
      if (current()) _replace(exchangeId, (_) => saved);
      return null;
    } on Exception catch (error) {
      if (current()) {
        _replace(exchangeId, (e) => e.copyWith(isLiked: !isLiked));
      }
      return error;
    }
  }

  void _replace(String id, ChatExchange Function(ChatExchange) update) {
    _update(
      (chat) => chat.withExchanges([
        for (final e in chat.exchanges) e.id == id ? update(e) : e,
      ]),
    );
  }
}
