/// Every error the backend can answer, by the `code` its body carries (#214):
/// the mirror of `ErrorCode` in `backend/core/errors/codes.py`.
///
/// The app decides on the code, never on the body's `detail`, which is English
/// for a log. `test/contract/api_contract_test.dart` holds this list equal to
/// the backend's, through the committed OpenAPI, so a code added on one side
/// fails `make frontend` until it is added here with its message
/// (`core/utils/error_text.dart`).
enum ErrorCode {
  // The request itself, refused before any route ran.
  invalidRequest('invalid_request'),
  routeNotFound('route_not_found'),
  methodNotAllowed('method_not_allowed'),
  tooManyRequests('too_many_requests'),
  internalError('internal_error'),

  // His session: every 401.
  notSignedIn('not_signed_in'),
  invalidToken('invalid_token'),
  studentNoLongerExists('student_no_longer_exists'),
  invalidRefreshToken('invalid_refresh_token'),
  invalidGoogleToken('invalid_google_token'),
  studentNotFound('student_not_found'),

  // His goals, lessons and tutor chat.
  noActiveGoal('no_active_goal'),
  goalNotFound('goal_not_found'),
  notAGoal('not_a_goal'),
  lessonsNotReady('lessons_not_ready'),
  unknownQuestion('unknown_question'),
  messageNotFound('message_not_found'),

  // A service the backend calls failed: always a 5xx, never his session.
  googleUnreachable('google_unreachable'),
  geminiNoAnswer('gemini_no_answer'),
  geminiKeyRejected('gemini_key_rejected'),
  geminiQuotaExhausted('gemini_quota_exhausted'),
  geminiFailed('gemini_failed'),
  geminiTimedOut('gemini_timed_out'),
  geminiUnreachable('gemini_unreachable');

  const ErrorCode(this.wire);

  /// The code as the backend writes it.
  final String wire;

  /// The member [wire] names, or null for a code this build does not know —
  /// a newer backend, or a body from something else (a proxy's error page).
  static ErrorCode? fromWire(Object? wire) {
    for (final code in values) {
      if (code.wire == wire) return code;
    }
    return null;
  }
}
