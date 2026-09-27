"""The rules tests/conftest.py applies at collection, checked (#206)."""

import pytest

from backend.tests.conftest import LIVE_DIR, misplaced

HERE = LIVE_DIR.parent / "test_suite_rules.py"
IN_LIVE = LIVE_DIR / "test_gemini.py"


@pytest.mark.parametrize(
    ("marked_live", "path", "wrong"),
    [(True, IN_LIVE, False), (False, HERE, False), (True, HERE, True), (False, IN_LIVE, True)],
    ids=["live-in-live", "default-outside", "live-outside", "unmarked-in-live"],
)
def test_live_tests_live_in_live_and_only_there(marked_live, path, wrong):
    assert misplaced(marked_live, path) is wrong


def test_a_test_on_the_database_is_marked_db(test_db, request):
    assert request.node.get_closest_marker("db")


def test_a_test_without_it_is_not(request):
    assert request.node.get_closest_marker("db") is None
