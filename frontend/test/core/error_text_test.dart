import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/api/error_code.dart';
import 'package:goal_getter/core/utils/error_text.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// One sentence per way a call fails (#221): an answer the app cannot read is
/// not a server that cannot be reached.
void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  String said(ErrorCode? code, [String detail = 'English for the log']) =>
      errorText(ApiException(500, detail, code: code), l10n);

  test('each failure says what happened', () {
    expect(
      errorText(const MalformedResponse('a TypeError'), l10n),
      l10n.unreadableResponse,
    );
    expect(errorText(const TimedOut(), l10n), l10n.serverTimedOut);
    expect(
      errorText(const ServerUnreachable('refused'), l10n),
      l10n.serverUnreachable,
    );
    expect(l10n.unreadableResponse, isNot(l10n.serverUnreachable));
  });

  test("an answer is said by its code, never by the backend's text", () {
    expect(said(ErrorCode.tooManyRequests), l10n.tooManyTries);
    expect(said(ErrorCode.noActiveGoal), l10n.noActiveGoal);
    expect(said(ErrorCode.geminiKeyRejected), l10n.errorAiUnavailable);
    expect(said(ErrorCode.invalidToken), l10n.errorSessionEnded);
    for (final code in ErrorCode.values.where((c) => c != ErrorCode.notAGoal)) {
      expect(said(code), isNot('English for the log'), reason: code.wire);
    }
  });

  test('a code this build does not know is the generic failure', () {
    expect(said(null), l10n.errorSomethingWentWrong);
  });

  test("not a goal shows Gemini's reasoning, in his language", () {
    expect(
      said(ErrorCode.notAGoal, 'Isso não é uma meta'),
      'Isso não é uma meta',
    );
  });
}
