"""Comments state what is true now, and why (CLAUDE.md, "Documentation").

How the code got here belongs in the pull request and the issue: a comment that
narrates it goes stale, costs tokens on every read, and invites the reader to
reason about code that no longer exists. An issue reference that points to a
still-relevant decision is rationale, and one per decision is plenty.

Two checks, both on the text of the file, and neither reads prose it cannot
judge:

- **At most `MAX_ISSUE_REFERENCES` issue references per file.** A file embodies
  a few decisions; more references than that is a changelog.
- **No `since #N`, `until #N`, `before #N`, `after #N` or `as of #N`.** Each one
  dates a sentence by the change that made it true, which is the history itself.

Phrases like "used to" and "no longer" are left to review: "the key used to
sign" and "a student who no longer exists" are present tense.

Migrations are exempt: a revision's docstring describes a change by definition.
"""

import re

MAX_ISSUE_REFERENCES = 3

# `#228`, never a `&#39;` entity, a `##` heading or a colour.
ISSUE_REFERENCE = re.compile(r"(?<![\w&#])#\d{1,5}\b")
DATED_BY_A_CHANGE = re.compile(r"\b(?:since|until|before|after|as of)\s+#\d+", re.IGNORECASE)

HELP = "a comment states what is true now; the history belongs in the PR (CLAUDE.md)"


def comment_violations(source: str, norm_path: str) -> list[tuple[int, str]]:
    """Where `source`, the file at `norm_path`, narrates history: [(line, message)]."""
    if "backend/alembic/versions/" in norm_path:
        return []
    errors: list[tuple[int, str]] = []
    references = ISSUE_REFERENCE.findall(source)
    if len(references) > MAX_ISSUE_REFERENCES:
        message = (
            f"{len(references)} issue references, at most {MAX_ISSUE_REFERENCES}: "
            f"keep one per still-relevant decision - {HELP}"
        )
        errors.append((0, message))
    for match in DATED_BY_A_CHANGE.finditer(source):
        line = source.count("\n", 0, match.start()) + 1
        errors.append((line, f"'{match.group(0)}' dates a sentence by a change - {HELP}"))
    return errors
