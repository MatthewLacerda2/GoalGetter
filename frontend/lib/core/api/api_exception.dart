import 'dart:convert';

/// A non-2xx answer from the backend.
///
/// [detail] is the sentence to show or log: FastAPI's `{"detail": "..."}` when
/// the body carries one, else the HTTP status. [rawDetail] keeps the body's
/// `detail` unnarrowed, because FastAPI's 422 answers a list of field errors
/// and a caller that wants them should not have to re-parse the body.
class ApiException implements Exception {
  const ApiException(this.status, this.detail, {this.rawDetail, this.path});

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
  final String? path;

  @override
  String toString() => 'ApiException($status, $detail)';
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
