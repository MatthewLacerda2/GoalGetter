import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The status slowapi answers a rate-limited call with.
const int tooManyRequests = 429;

/// The one sentence the app says about a failed call, whichever shape shows it
/// (`FailureView` or `showFailure`, both in `core/widgets/failure.dart`).
///
/// One case per [ApiFailure] (#221), then whatever else was thrown:
///
///  * a 429 — the body slowapi sends carries no `detail` to show, so the rate
///    limit is spelled out here;
///  * any other answer from the backend — its own `detail`, which for a 400
///    from goal creation is Gemini's reasoning;
///  * an answer the app cannot read — said as such, not as a server that is
///    down: the server is up, and this build and it disagree;
///  * no answer in time;
///  * no answer at all (offline, DNS, CORS) — "could not reach the server",
///    which is also what is said when nothing (null) was thrown, or something
///    that did not come from a call.
String errorText(Object? error, AppLocalizations l10n) => switch (error) {
      ApiException(status: tooManyRequests) => l10n.tooManyTries,
      ApiException(:final detail) => detail,
      MalformedResponse() => l10n.unreadableResponse,
      TimedOut() => l10n.serverTimedOut,
      ServerUnreachable() || _ => l10n.serverUnreachable,
    };
