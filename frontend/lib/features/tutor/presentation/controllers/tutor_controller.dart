import 'dart:async';

import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/features/tutor/data/tutor_api.dart';
import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:goal_getter/features/tutor/presentation/controllers/tutor_state.dart';

part 'tutor_controller.g.dart';

@riverpod
class TutorController extends _$TutorController {
  TutorApi get _api => ref.read(tutorApiProvider);

  @override
  TutorState build() {
    Future.microtask(load);
    return const TutorState();
  }

  /// Loads the newest page, replacing whatever was there.
  Future<void> load() async {
    if (state.load != TutorLoad.loading) state = const TutorState();
    try {
      final page = await _api.list();
      state = TutorState(
        load: TutorLoad.ready,
        exchanges: page.reversed.toList(),
        hasMore: page.length == TutorApi.pageSize,
      );
    } on ApiException catch (e) {
      final noGoal = e.status == 404 && e.detail == TutorApi.noActiveGoal;
      state = TutorState(
        load: noGoal ? TutorLoad.noActiveGoal : TutorLoad.failed,
        loadFailure: e,
      );
    } on Exception catch (e) {
      state = TutorState(load: TutorLoad.failed, loadFailure: e);
    }
  }

  /// Loads the page before the oldest loaded exchange. After a failure only
  /// an explicit [retry] tries again, so scrolling does not hammer the server.
  Future<void> loadOlder({bool retry = false}) async {
    final s = state;
    if (s.load != TutorLoad.ready || !s.hasMore || s.isLoadingMore) return;
    if (s.loadMoreFailed && !retry) return;
    state = s.copyWith(isLoadingMore: true, loadMoreFailure: null);
    try {
      final page = await _api.list(before: s.exchanges.first.createdAt);
      state = state.copyWith(
        exchanges: [...page.reversed, ...state.exchanges],
        hasMore: page.length == TutorApi.pageSize,
        isLoadingMore: false,
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoadingMore: false, loadMoreFailure: e);
    }
  }

  /// Sends [text], shown at once as a pending bubble. Returns what the call
  /// threw, or null when it went through: the bubble stays, marked failed, and
  /// the caller gives the text back to the student and says why.
  Future<Object?> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.isSending) return null;
    state = state.copyWith(pending: PendingSend(message));
    try {
      final exchange = await _api.send(message);
      state = state.copyWith(
        exchanges: [...state.exchanges, exchange],
        pending: null,
      );
      return null;
    } on Exception catch (e) {
      state = state.copyWith(pending: PendingSend(message, failed: true));
      return e;
    }
  }

  /// Sets the like at once, then confirms it with the backend. Returns what
  /// the backend threw, with the like put back, or null when it was saved.
  Future<Object?> setLike(String exchangeId, bool isLiked) async {
    _replace(exchangeId, (e) => e.copyWith(isLiked: isLiked));
    try {
      final saved = await _api.setLike(exchangeId, isLiked);
      _replace(exchangeId, (_) => saved);
      return null;
    } on Exception catch (error) {
      _replace(exchangeId, (e) => e.copyWith(isLiked: !isLiked));
      return error;
    }
  }

  void _replace(String id, ChatExchange Function(ChatExchange) update) {
    state = state.copyWith(
      exchanges: [for (final e in state.exchanges) e.id == id ? update(e) : e],
    );
  }
}
