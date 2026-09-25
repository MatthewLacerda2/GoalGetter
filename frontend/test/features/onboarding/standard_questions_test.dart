import 'package:flutter_test/flutter_test.dart';
import 'package:goal_getter/features/onboarding/presentation/standard_question_text.dart';
import 'package:goal_getter/l10n/generated/app_localizations.dart';
import 'package:goal_getter/l10n/generated/app_localizations_en.dart';

/// The standard onboarding questions as the backend ships them (#132), copied
/// from `backend/services/onboarding/standard_questions.py`.
///
/// Written out rather than fetched, the same way the intro icons were kept in
/// step with the backend's enum: the keys are the contract between the two
/// sides, and a test that derived them from one side could never disagree with
/// it.
const backendStandardQuestions = <String, List<String>>{
  'age': ['under18', '18to24', '25to39', '40plus'],
  'purpose': ['school', 'work', 'project', 'curiosity'],
  'level': ['nothing', 'little', 'enough', 'deep'],
  'time': ['minutes', 'quarter', 'half', 'hour'],
};

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  test('every question the backend asks has a sentence to draw', () {
    for (final key in backendStandardQuestions.keys) {
      expect(standardQuestionLabel(l10n, key), isNotNull, reason: key);
    }
    expect(standardQuestionText.keys, backendStandardQuestions.keys);
  });

  test('every option the backend offers has a sentence to draw', () {
    for (final entry in backendStandardQuestions.entries) {
      for (final option in entry.value) {
        expect(
          standardOptionLabel(l10n, entry.key, option),
          isNotNull,
          reason: '${entry.key}.$option',
        );
      }
    }
    expect(standardOptionText.length, 16);
  });

  test('a key this build does not know draws nothing rather than blank', () {
    expect(standardQuestionLabel(l10n, 'favourite-colour'), isNull);
    expect(standardOptionLabel(l10n, 'age', 'in-dog-years'), isNull);
  });

  test('option keys are read per question, not across them', () {
    expect(standardOptionLabel(l10n, 'age', 'school'), isNull);
    expect(standardOptionLabel(l10n, 'purpose', 'school'), isNotNull);
  });
}
