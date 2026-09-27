import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/core/api/api_exception.dart';
import 'package:goal_getter/core/utils/error_text.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// One sentence per way a call fails (#221): an answer the app cannot read is
/// not a server that cannot be reached.
void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('each failure says what happened', () {
    expect(
      errorText(const ApiException(404, 'No active goal'), l10n),
      'No active goal',
    );
    expect(errorText(const ApiException(429, 'HTTP 429'), l10n),
        l10n.tooManyTries);
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
}
