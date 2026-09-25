import 'package:goal_getter/l10n/generated/app_localizations.dart';

/// Where the backend's standard onboarding questions meet the ARB files (#132).
///
/// The backend owns *which* questions exist and in what order: `POST /goals`
/// answers with a key per question and a key per option, and the English it
/// stores for the prompts lives in its own
/// `services/onboarding/standard_questions.py`. This file owns the other half —
/// what the student actually reads — and it is a table of keys to ARB getters
/// rather than a copy of the questions, so a sentence still exists once, in
/// five locales, and `make front-lint` still fails a locale that is missing one.
///
/// A key with no entry here is skipped by the screen rather than drawn blank: a
/// question added to the backend before this table catches up is one question
/// the student is not asked, never a row of empty tiles. The pair is pinned by
/// `test/features/onboarding/standard_questions_test.dart`.

/// The sentence of each question, by its key.
final Map<String, String Function(AppLocalizations)> standardQuestionText = {
  'age': (l10n) => l10n.standardQuestionAge,
  'purpose': (l10n) => l10n.standardQuestionPurpose,
  'level': (l10n) => l10n.standardQuestionLevel,
  'time': (l10n) => l10n.standardQuestionTime,
};

/// The text of each option, by `'<question key>.<option key>'` — option keys
/// are unique inside a question, not across them.
final Map<String, String Function(AppLocalizations)> standardOptionText = {
  'age.under18': (l10n) => l10n.standardOptionAgeUnder18,
  'age.18to24': (l10n) => l10n.standardOptionAge18to24,
  'age.25to39': (l10n) => l10n.standardOptionAge25to39,
  'age.40plus': (l10n) => l10n.standardOptionAge40plus,
  'purpose.school': (l10n) => l10n.standardOptionPurposeSchool,
  'purpose.work': (l10n) => l10n.standardOptionPurposeWork,
  'purpose.project': (l10n) => l10n.standardOptionPurposeProject,
  'purpose.curiosity': (l10n) => l10n.standardOptionPurposeCuriosity,
  'level.nothing': (l10n) => l10n.standardOptionLevelNothing,
  'level.little': (l10n) => l10n.standardOptionLevelLittle,
  'level.enough': (l10n) => l10n.standardOptionLevelEnough,
  'level.deep': (l10n) => l10n.standardOptionLevelDeep,
  'time.minutes': (l10n) => l10n.standardOptionTimeMinutes,
  'time.quarter': (l10n) => l10n.standardOptionTimeQuarter,
  'time.half': (l10n) => l10n.standardOptionTimeHalf,
  'time.hour': (l10n) => l10n.standardOptionTimeHour,
};

/// The question's sentence, or null when this build does not know the key.
String? standardQuestionLabel(AppLocalizations l10n, String questionKey) =>
    standardQuestionText[questionKey]?.call(l10n);

/// The option's text, or null when this build does not know the key.
String? standardOptionLabel(
  AppLocalizations l10n,
  String questionKey,
  String optionKey,
) => standardOptionText['$questionKey.$optionKey']?.call(l10n);
