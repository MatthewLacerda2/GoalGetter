import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';

/// Where the first page of the chat stands.
enum TutorLoad { loading, ready, noActiveGoal, failed }

/// The student's message while it is on its way, or after it failed. At most
/// one exists: the send button is disabled while one is in flight, and a new
/// send replaces a failed one (whose text went back into the input).
///
/// Why it failed is not here: the screen says that once, in a snackbar.
class PendingSend {
  const PendingSend(this.text, {this.failed = false});

  final String text;
  final bool failed;
}

const _keep = Object();

class TutorState {
  const TutorState({
    this.load = TutorLoad.loading,
    this.loadFailure,
    this.exchanges = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.pending,
  });

  final TutorLoad load;

  /// What the first page threw when [load] failed; null when there was
  /// nothing to throw.
  final Object? loadFailure;

  /// Oldest first, as the chat reads.
  final List<ChatExchange> exchanges;
  final bool hasMore;
  final bool isLoadingMore;

  /// What the page before the oldest exchange threw, or null when nothing
  /// failed. Only an explicit retry tries again.
  final Object? loadMoreFailure;
  final PendingSend? pending;

  bool get isSending => pending != null && !pending!.failed;

  bool get loadMoreFailed => loadMoreFailure != null;

  TutorState copyWith({
    List<ChatExchange>? exchanges,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreFailure = _keep,
    Object? pending = _keep,
  }) => TutorState(
    load: load,
    loadFailure: loadFailure,
    exchanges: exchanges ?? this.exchanges,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailure: identical(loadMoreFailure, _keep)
        ? this.loadMoreFailure
        : loadMoreFailure,
    pending: identical(pending, _keep) ? this.pending : pending as PendingSend?,
  );
}
