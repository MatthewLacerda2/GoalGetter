import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';

/// Where the first page of the chat stands.
enum TutorLoad { loading, ready, noActiveGoal, failed }

/// The student's message while it is on its way, or after it failed. At most
/// one exists: the send button is disabled while one is in flight, and a new
/// send replaces a failed one (whose text went back into the input).
class PendingSend {
  const PendingSend(this.text, {this.failed = false, this.error});

  final String text;
  final bool failed;

  /// The backend's detail; null when the server could not be reached.
  final String? error;
}

const _keep = Object();

class TutorState {
  const TutorState({
    this.load = TutorLoad.loading,
    this.loadError,
    this.exchanges = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.pending,
  });

  final TutorLoad load;

  /// The backend's detail when [load] failed; null when unreachable.
  final String? loadError;

  /// Oldest first, as the chat reads.
  final List<ChatExchange> exchanges;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final PendingSend? pending;

  bool get isSending => pending != null && !pending!.failed;

  TutorState copyWith({
    List<ChatExchange>? exchanges,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Object? pending = _keep,
  }) => TutorState(
    load: load,
    loadError: loadError,
    exchanges: exchanges ?? this.exchanges,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    pending: identical(pending, _keep) ? this.pending : pending as PendingSend?,
  );
}
