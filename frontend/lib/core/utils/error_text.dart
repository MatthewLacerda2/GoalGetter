import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// The sentence to show for a failed backend call: the backend's own `detail`
/// when it answered, else a localized "could not reach the server" (offline,
/// DNS, CORS: the transport threw before any answer).
String errorText(Object error, AppLocalizations l10n) {
  if (error is ApiException) return error.detail;
  return l10n.serverUnreachable;
}
