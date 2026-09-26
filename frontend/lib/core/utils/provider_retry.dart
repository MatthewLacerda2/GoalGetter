/// The retry policy of every `ProviderScope` and `ProviderContainer`: none.
///
/// Riverpod 3 retries a failed provider on its own, with a backoff, and shows
/// it loading meanwhile (#164). That would turn a failed load into a spinner
/// that never says what happened, where this app shows the failure and hands
/// the student the retry (`lib/core/widgets/failure.dart`) — the behaviour it
/// had on Riverpod 2, kept. The tests pass it too, so they run under the same
/// policy the app does.
Duration? noAutomaticRetry(int retryCount, Object error) => null;
