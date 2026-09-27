import 'package:flutter/foundation.dart';

import 'package:goal_getter/features/tutor/domain/chat_exchange.dart';

/// What the tutor screen shows once the chat's first page has come back.
///
/// Loading that page, and a failure to, are the controller's own `AsyncValue`
/// (loading, error), so whatever the call throws lands in the error with its
/// retry. Equality is hand-written, as the lesson's is (#223); exchanges
/// compare by identity, being the server's objects, replaced whenever one
/// changes.
@immutable
sealed class TutorState {
  const TutorState();
}

/// The student has no active goal, and the chat belongs to one.
final class TutorNoActiveGoal extends TutorState {
  const TutorNoActiveGoal();

  @override
  bool operator ==(Object other) => other is TutorNoActiveGoal;

  @override
  int get hashCode => (TutorNoActiveGoal).hashCode;
}

/// The chat on the active goal.
final class TutorChat extends TutorState {
  const TutorChat({
    required this.exchanges,
    required this.older,
    this.pending,
  });

  /// Oldest first, as the chat reads.
  final List<ChatExchange> exchanges;

  /// Where the pages before the oldest exchange stand.
  final OlderPages older;

  /// The student's message while it is on its way, or after it failed.
  final PendingSend? pending;

  bool get isSending => pending is SendingMessage;

  TutorChat withExchanges(List<ChatExchange> exchanges) =>
      TutorChat(exchanges: exchanges, older: older, pending: pending);

  TutorChat withOlder(OlderPages older) =>
      TutorChat(exchanges: exchanges, older: older, pending: pending);

  TutorChat withPending(PendingSend? pending) =>
      TutorChat(exchanges: exchanges, older: older, pending: pending);

  @override
  bool operator ==(Object other) =>
      other is TutorChat &&
      listEquals(other.exchanges, exchanges) &&
      other.older == older &&
      other.pending == pending;

  @override
  int get hashCode => Object.hash(Object.hashAll(exchanges), older, pending);
}

/// The pages before the oldest loaded exchange.
@immutable
sealed class OlderPages {
  const OlderPages();
}

/// The oldest exchange is loaded: there is nothing before it.
final class NoOlderPages extends OlderPages {
  const NoOlderPages();

  @override
  bool operator ==(Object other) => other is NoOlderPages;

  @override
  int get hashCode => (NoOlderPages).hashCode;
}

/// There may be more, and nothing is asking for them.
final class MoreOlderPages extends OlderPages {
  const MoreOlderPages();

  @override
  bool operator ==(Object other) => other is MoreOlderPages;

  @override
  int get hashCode => (MoreOlderPages).hashCode;
}

/// The page before the oldest exchange is on its way.
final class LoadingOlderPages extends OlderPages {
  const LoadingOlderPages();

  @override
  bool operator ==(Object other) => other is LoadingOlderPages;

  @override
  int get hashCode => (LoadingOlderPages).hashCode;
}

/// That page failed with [cause]. Only an explicit retry tries again, so
/// scrolling does not hammer the server.
final class OlderPagesFailed extends OlderPages {
  const OlderPagesFailed(this.cause);

  final Object cause;

  @override
  bool operator ==(Object other) =>
      other is OlderPagesFailed && other.cause == cause;

  @override
  int get hashCode => Object.hash(OlderPagesFailed, cause);
}

/// The student's message before it is an exchange. At most one exists: the
/// send button is disabled while one is in flight, and a new send replaces a
/// failed one (whose text went back into the input).
///
/// Why it failed is not here: the screen says that once, in a snackbar.
@immutable
sealed class PendingSend {
  const PendingSend(this.text);

  final String text;
}

/// On its way to the tutor.
final class SendingMessage extends PendingSend {
  const SendingMessage(super.text);

  @override
  bool operator ==(Object other) =>
      other is SendingMessage && other.text == text;

  @override
  int get hashCode => Object.hash(SendingMessage, text);
}

/// It did not reach the tutor; the bubble stays, marked failed.
final class FailedMessage extends PendingSend {
  const FailedMessage(super.text);

  @override
  bool operator ==(Object other) =>
      other is FailedMessage && other.text == text;

  @override
  int get hashCode => Object.hash(FailedMessage, text);
}
