/// Comments state what is true now, and why (CLAUDE.md, "Documentation"), the
/// mirror of `backend/tests/comment_rules.py`.
///
/// How the code got here belongs in the pull request and the issue: a comment
/// that narrates it goes stale, costs tokens on every read, and invites the
/// reader to reason about code that no longer exists. An issue reference that
/// points to a still-relevant decision is rationale, and one per decision is
/// plenty. Two checks on the text of the file:
///
/// - `issue-references`: at most [maxIssueReferences] per file. A file
///   embodies a few decisions; more references than that is a changelog.
/// - `dated-by-a-change`: no "since #N", "until #N", "before #N", "after #N"
///   or "as of #N" — each dates a sentence by the change that made it true,
///   which is the history itself.
///
/// "used to" and "no longer" are left to review: "the key used to sign" and
/// "a goal that no longer exists" are present tense.
library;

import 'dart_source.dart';

/// At most this many issue references in one file.
const int maxIssueReferences = 3;

/// `#228`, never a `&#39;` entity or a `##` heading.
final RegExp _issueReference = RegExp(r'(?<![\w&#])#\d{1,5}\b');

final RegExp _datedByAChange = RegExp(
  r'\b(?:since|until|before|after|as of)\s+#\d+',
  caseSensitive: false,
);

const String _help =
    'a comment states what is true now; the history belongs in the PR '
    '(CLAUDE.md)';

/// Where [source] narrates history.
List<Violation> commentViolations(String source) {
  final count = _issueReference.allMatches(source).length;
  return [
    if (count > maxIssueReferences)
      Violation(
        0,
        'issue-references',
        '$count issue references, at most $maxIssueReferences: keep one per '
            'still-relevant decision - $_help',
      ),
    for (final match in _datedByAChange.allMatches(source))
      Violation(
        lineAt(source, match.start),
        'dated-by-a-change',
        "'${match.group(0)}' dates a sentence by a change - $_help",
      ),
  ];
}
