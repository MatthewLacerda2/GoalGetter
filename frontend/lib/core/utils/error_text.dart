import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The one sentence the app says about a failed call, whichever shape shows it
/// (`FailureView` or `showFailure`, both in `core/widgets/failure.dart`).
///
/// One case per [ApiFailure], then whatever else was thrown:
///
///  * an answer from the backend — the message for its code, never the
///    body's `detail`, which is English for the log. The exception is a prompt
///    that is not a goal: its detail is Gemini's reasoning, written in the
///    student's language, and is the most useful thing to show him;
///  * an answer the app cannot read — said as such, not as a server that is
///    down: the server is up, and this build and it disagree;
///  * no answer in time;
///  * no answer at all (offline, DNS, CORS) — "could not reach the server",
///    which is also what is said when nothing (null) was thrown, or something
///    that did not come from a call.
String errorText(Object? error, AppLocalizations l10n) => switch (error) {
  ApiException(code: ErrorCode.notAGoal, :final detail) => detail,
  ApiException(:final code) => _codeText(code, l10n),
  MalformedResponse() => l10n.unreadableResponse,
  TimedOut() => l10n.serverTimedOut,
  ServerUnreachable() || _ => l10n.serverUnreachable,
};

/// The message for each code the backend can answer. Exhaustive, so a code
/// added to [ErrorCode] does not compile until it has one; null — a code this
/// build does not know, or none — is the generic failure.
String _codeText(ErrorCode? code, AppLocalizations l10n) => switch (code) {
  ErrorCode.notSignedIn ||
  ErrorCode.invalidToken ||
  ErrorCode.studentNoLongerExists ||
  ErrorCode.invalidRefreshToken ||
  ErrorCode.studentNotFound => l10n.errorSessionEnded,
  ErrorCode.invalidGoogleToken => l10n.errorGoogleRejected,
  ErrorCode.googleUnreachable => l10n.errorGoogleUnreachable,
  ErrorCode.tooManyRequests => l10n.tooManyTries,
  ErrorCode.noActiveGoal => l10n.noActiveGoal,
  ErrorCode.goalNotFound => l10n.goalNotFound,
  ErrorCode.lessonsNotReady => l10n.lessonsStillPreparing,
  ErrorCode.geminiNoAnswer ||
  ErrorCode.geminiKeyRejected ||
  ErrorCode.geminiQuotaExhausted ||
  ErrorCode.geminiFailed ||
  ErrorCode.geminiTimedOut ||
  ErrorCode.geminiUnreachable => l10n.errorAiUnavailable,
  // Nothing for him to do but try again: the app and the backend
  // disagree, or something failed on our side. `notAGoal` is listed only
  // to keep the switch exhaustive: `errorText` shows Gemini's reasoning.
  ErrorCode.invalidRequest ||
  ErrorCode.routeNotFound ||
  ErrorCode.methodNotAllowed ||
  ErrorCode.internalError ||
  ErrorCode.notAGoal ||
  ErrorCode.unknownQuestion ||
  ErrorCode.messageNotFound ||
  null => l10n.errorSomethingWentWrong,
};
