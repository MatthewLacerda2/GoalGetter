"""The rules tests/conftest.py applies at collection, checked (#206)."""

import ast
import inspect
import pkgutil

import pytest

from backend.tests.conftest import LIVE_DIR, misplaced
from backend.tests.fixtures.code import modules_under

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


def unspecced_patches() -> list[str]:
    """Every `patch(target)` in the suite that replaces an async function with a
    bare mock - one that answers any arguments at all.

    A use case called with its arguments swapped, missing or misnamed passes
    against a bare mock everywhere, and the live suite that would catch it runs
    only on pull requests that touch Gemini. `autospec=True` holds the mock to
    the real signature. A patch that brings its own stand-in (`new`, as
    `fixtures/jobs.py` does, binding to the signature itself) is its own answer.
    The target is read the way the test computes it - a constant, or a constant
    plus a suffix - and resolved to what it names."""
    found = []
    for module in modules_under("tests"):
        for node in ast.walk(ast.parse(inspect.getsource(module))):
            if not (isinstance(node, ast.Call) and isinstance(node.func, ast.Name)):
                continue
            keywords = {keyword.arg for keyword in node.keywords}
            if node.func.id != "patch" or len(node.args) != 1 or keywords & SPECIFIED:
                continue
            try:
                target = eval(
                    compile(ast.Expression(node.args[0]), "<patch>", "eval"), vars(module)
                )
                replaced = pkgutil.resolve_name(target)
            except NameError, AttributeError, ImportError, ValueError, TypeError:
                continue
            if inspect.iscoroutinefunction(replaced):
                found.append(f"{module.__name__}:{node.lineno} {target}")
    return found


# What makes a patch answer to the real signature, or bring its own stand-in.
SPECIFIED = {"autospec", "spec", "spec_set", "new", "new_callable"}


def test_every_patched_async_function_is_held_to_its_signature():
    assert unspecced_patches() == []
