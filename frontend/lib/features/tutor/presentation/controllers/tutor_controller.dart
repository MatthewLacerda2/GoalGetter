import 'dart:async';

import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/features/tutor/data/tutor_api.dart';
import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';
import 'package:goal_getter/features/tutor/presentation/controllers/tutor_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:goal_getter/features/tutor/presentation/controllers/tutor_state.dart';

part 'tutor_controller.g.dart';

/// The backend's detail for [error], or null when there is none to show (the
/// server was not reached at all).
String? _detail(Object error) => error is ApiException ? error.detail : null;

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
        loadError: e.detail,
      );
    } on Exception {
      state = const TutorState(load: TutorLoad.failed);
    }
  }

  /// Loads the page before the oldest loaded exchange. After a failure only
  /// an explicit [retry] tries again, so scrolling does not hammer the server.
  Future<void> loadOlder({bool retry = false}) async {
    final s = state;
    if (s.load != TutorLoad.ready || !s.hasMore || s.isLoadingMore) return;
    if (s.loadMoreFailed && !retry) return;
    state = s.copyWith(isLoadingMore: true, loadMoreFailed: false);
    try {
      final page = await _api.list(before: s.exchanges.first.createdAt);
      state = state.copyWith(
        exchanges: [...page.reversed, ...state.exchanges],
        hasMore: page.length == TutorApi.pageSize,
        isLoadingMore: false,
      );
    } on Exception {
      state = state.copyWith(isLoadingMore: false, loadMoreFailed: true);
    }
  }

  /// Sends [text], shown at once as a pending bubble. Returns false when the
  /// send failed: the bubble stays, marked failed, and the caller gives the
  /// text back to the student.
  Future<bool> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.isSending) return true;
    state = state.copyWith(pending: PendingSend(message));
    try {
      final exchange = await _api.send(message);
      state = state.copyWith(
        exchanges: [...state.exchanges, exchange],
        pending: null,
      );
      return true;
    } on Exception catch (e) {
      state = state.copyWith(
        pending: PendingSend(message, failed: true, error: _detail(e)),
      );
      return false;
    }
  }

  /// Sets the like at once, then confirms it with the backend. Returns false,
  /// with the like put back, when the backend refused it.
  Future<bool> setLike(String exchangeId, bool isLiked) async {
    _replace(exchangeId, (e) => e.copyWith(isLiked: isLiked));
    try {
      final saved = await _api.setLike(exchangeId, isLiked);
      _replace(exchangeId, (_) => saved);
      return true;
    } on Exception {
      _replace(exchangeId, (e) => e.copyWith(isLiked: !isLiked));
      return false;
    }
  }

  void _replace(String id, ChatExchange Function(ChatExchange) update) {
    state = state.copyWith(
      exchanges: [for (final e in state.exchanges) e.id == id ? update(e) : e],
    );
  }
}
