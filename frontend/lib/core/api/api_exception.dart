import 'dart:convert';

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
/// (#221). The server's own error codes (#214) belong on [ApiException].
sealed class ApiFailure implements Exception {
  const ApiFailure({this.path});

  /// The request's path under `/api/v1`, for the log.
  final String? path;
}

/// A non-2xx answer from the backend.
///
/// [detail] is the sentence to show or log: FastAPI's `{"detail": "..."}` when
/// the body carries one, else the HTTP status. [rawDetail] keeps the body's
/// `detail` unnarrowed, because FastAPI's 422 answers a list of field errors
/// and a caller that wants them should not have to re-parse the body.
class ApiException extends ApiFailure {
  const ApiException(this.status, this.detail, {this.rawDetail, super.path});

  /// Builds the exception from a response body, whatever shape it has.
  factory ApiException.fromBody(int status, String body, {String? path}) {
    Object? raw;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) raw = decoded['detail'];
    } on FormatException {
      // Not JSON (a proxy error page, an empty body): keep the status.
    }
    return ApiException(
      status,
      readErrorDetail(raw, 'HTTP $status'),
      rawDetail: raw,
      path: path,
    );
  }

  final int status;
  final String detail;
  final Object? rawDetail;

  @override
  String toString() => 'ApiException($status, $detail)';
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

/// The sentence carried by a FastAPI `detail`, in the order tried: a plain
/// string (almost every endpoint); a 422's list of `{msg}` field errors,
/// joined; anything else falls back to [fallback].
String readErrorDetail(Object? detail, String fallback) {
  if (detail is String && detail.isNotEmpty) return detail;
  if (detail is List) {
    final messages = detail
        .whereType<Map<String, dynamic>>()
        .map((error) => error['msg'])
        .whereType<String>()
        .toList();
    if (messages.isNotEmpty) return messages.join('; ');
  }
  return fallback;
}
