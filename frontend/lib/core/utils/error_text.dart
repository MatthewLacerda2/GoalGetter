import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The status slowapi answers a rate-limited call with.
const int tooManyRequests = 429;

/// The one sentence the app says about a failed call, whichever shape shows it
/// (`FailureView` or `showFailure`, both in `core/widgets/failure.dart`).
///
/// Three cases, in order:
///
///  * a 429 — the body slowapi sends carries no `detail` to show, so the rate
///    limit is spelled out here;
///  * any other answer from the backend — its own `detail`, which for a 400
///    from goal creation is Gemini's reasoning;
///  * no answer at all (null, or the transport threw before one: offline, DNS,
///    CORS) — "could not reach the server".
String errorText(Object? error, AppLocalizations l10n) {
  if (error is! ApiException) return l10n.serverUnreachable;
  if (error.status == tooManyRequests) return l10n.tooManyTries;
  return error.detail;
}
