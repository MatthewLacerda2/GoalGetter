import 'dart:convert';

import 'package:goal_getter/core/api/error_code.dart';

/// Every way a call to the backend can fail, as the API layer throws it
/// (`ApiClient`). Four cases, one sentence each for the student
/// (`core/utils/error_text.dart`), and a screen that switches on them is told
/// by the compiler when a fifth arrives:
///
///  * [ApiException] — the backend answered, with a non-2xx status;
///  * [MalformedResponse] — it answered 2xx, in a shape this build cannot read;
///  * [TimedOut] — nothing answered within `ApiClient.timeout`;
///  * [ServerUnreachable] — the request never got an answer: offline, DNS,
///    CORS, a dropped connection.
///
/// All four are [Exception]s, so a controller's `on Exception` catches every
/// one of them — a response that fails to parse used to throw a `TypeError`,
/// which is an `Error`, got past those catches and left a spinner up forever
/// (#221). The server's own error code (#214) is [ApiException.code].
sealed class ApiFailure implements Exception {
  const ApiFailure({this.path});

  /// The request's path under `/api/v1`, for the log.
  final String? path;
}

/// A non-2xx answer from the backend, whose body is
/// `{"code": "...", "detail": "..."}` (#214).
///
/// [code] is what the app decides on; null when the body carries none this
/// build knows (a proxy's error page, a newer backend), which is said as a
/// generic failure. [detail] is English for the log — or the HTTP status when
/// the body has none — and is never compared: the one code whose detail is
/// shown is [ErrorCode.notAGoal], Gemini's reasoning in the student's language.
class ApiException extends ApiFailure {
  const ApiException(this.status, this.detail, {this.code, super.path});

  /// Builds the exception from a response body, whatever shape it has.
  factory ApiException.fromBody(int status, String body, {String? path}) {
    Object? code;
    Object? detail;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        code = decoded['code'];
        detail = decoded['detail'];
      }
    } on FormatException {
      // Not JSON (a proxy error page, an empty body): keep the status.
    }
    final forTheLog = detail is String && detail.isNotEmpty
        ? detail
        : 'HTTP $status';
    return ApiException(
      status,
      forTheLog,
      code: ErrorCode.fromWire(code),
      path: path,
    );
  }

  final int status;
  final String detail;
  final ErrorCode? code;

  @override
  String toString() => 'ApiException($status, ${code?.wire}, $detail)';
}

/// A 2xx answer this build cannot read: not JSON, or JSON of another shape
/// than the reader expects — a backend field renamed or retyped. [cause] is
/// what the reader threw, kept for the log.
class MalformedResponse extends ApiFailure {
  const MalformedResponse(this.cause, {super.path});

  final Object cause;

  @override
  String toString() => 'MalformedResponse($path: $cause)';
}

/// No answer within the client's timeout. The request may still have landed:
/// nothing that is not safe to repeat should be repeated on this alone.
class TimedOut extends ApiFailure {
  const TimedOut({super.path});

  @override
  String toString() => 'TimedOut($path)';
}

/// The request never got an answer: the transport itself failed. [cause] is
/// the transport's exception, kept for the log.
class ServerUnreachable extends ApiFailure {
  const ServerUnreachable(this.cause, {super.path});

  final Object cause;

  @override
  String toString() => 'ServerUnreachable($path: $cause)';
}
