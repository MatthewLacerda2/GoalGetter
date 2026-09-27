"""Comments state what is true now: the history gate fails a changelog, not a reason.

The references are built with `ref()` rather than written out, so this file
does not trip the rule it tests.
"""

import pytest

from backend.tests.backend_linter import check_source
from backend.tests.comment_rules import MAX_ISSUE_REFERENCES

SERVICE = "backend/services/example.py"


def ref(number: int) -> str:
    return "#" + str(number)


def messages(source: str, path: str = SERVICE) -> list[str]:
    return [message for _line, message in check_source(source, path)]


def test_one_reference_per_decision_passes():
    references = ", ".join(ref(n) for n in range(100, 100 + MAX_ISSUE_REFERENCES))
    source = f'"""Three decisions ({references})."""\n\nX = 1\n'

    assert messages(source) == []


def test_a_file_past_the_cap_fails_once_with_the_count():
    references = " ".join(ref(n) for n in range(100, 101 + MAX_ISSUE_REFERENCES))
    source = f"# {references}\nX = 1\n"

    found = [m for m in messages(source) if "issue references" in m]

    assert len(found) == 1
    assert found[0].startswith(f"{MAX_ISSUE_REFERENCES + 1} issue references")


@pytest.mark.parametrize("word", ["since", "Until", "before", "after", "as of"])
def test_a_sentence_dated_by_a_change_fails_on_its_line(word: str):
    source = f"X = 1\n# {word} {ref(157)} the schema is built by migrations\n"

    found = check_source(source, SERVICE)

    assert [line for line, message in found if "dates a sentence" in message] == [2]


@pytest.mark.parametrize(
    "text",
    [
        "# the key used to sign the token",
        "# a student who no longer exists is a 401",
        "# a colour #12ab34 and an entity &#39; are not references",
        "# a reason, and the issue that decided it (" + "#" + "134)",
    ],
)
def test_present_tense_and_lookalikes_pass(text: str):
    assert messages(f"{text}\nX = 1\n") == []


def test_a_migration_is_history_by_definition():
    path = "backend/alembic/versions/0001_example.py"
    source = f'"""Drops lessons ({ref(131)}), since {ref(131)} ({ref(1)} {ref(2)} {ref(3)})."""\n'

    assert messages(source, path) == []
