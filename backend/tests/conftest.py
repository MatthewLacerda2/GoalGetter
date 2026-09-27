from pathlib import Path

import pytest
from hypothesis import settings as hypothesis_settings

# The property tests (#207), made a gate: the same examples on every run
# (`derandomize`) - a gate that goes red on one run in fifty is one nobody
# believes - no example database written into the mounted worktree, and no
# per-example deadline, which a loaded machine misses on arithmetic that is fine.
hypothesis_settings.register_profile("gate", derandomize=True, database=None, deadline=None)
hypothesis_settings.load_profile("gate")

# Import all fixtures so pytest can discover them. `environment` comes FIRST: it
# pins every setting the suite reads, and nothing may import the settings before
# it (#207). `network` next: it raises the network guard, which must be up before
# any other module imports the app (#205). `waiting` after, for the same reason:
# a module that binds `asyncio.sleep` on import must bind the guarded one (#206).
pytest_plugins = [
    "backend.tests.fixtures.environment",
    "backend.tests.fixtures.network",
    "backend.tests.fixtures.waiting",
    "backend.tests.fixtures.database",
    "backend.tests.fixtures.auth",
    "backend.tests.fixtures.users",
    "backend.tests.fixtures.clients",
    "backend.tests.fixtures.goals",
    "backend.tests.fixtures.lessons",
    "backend.tests.fixtures.chat",
]

# The markers themselves are registered in backend/pyproject.toml, where
# `strict` makes any other name a failure (#206).
LIVE = "live"
DB = "db"
LIVE_DIR = Path(__file__).parent / "live"

# The fixture every database test reaches, directly or through another fixture.
DATABASE_FIXTURE = "setup_test_db"


@pytest.hookimpl
def pytest_addoption(parser):
    parser.addoption(
        "--live",
        action="store_true",
        help="run ONLY the tests marked live, against the real Gemini and YouTube "
        "APIs (spends real quota; `make test-live`)",
    )


def misplaced(marked_live: bool, path: Path) -> bool:
    """A live test lives in tests/live/, and only live tests do (#206).

    One outside it runs nowhere: the default suite skips it and `make test-live`
    collects only that folder. One inside it unmarked runs in the default suite,
    where the network guard fails it - but only after the folder stopped being
    what its name says."""
    return marked_live != path.is_relative_to(LIVE_DIR)


@pytest.hookimpl(tryfirst=True)
def pytest_collection_modifyitems(config, items):
    """Three rules, applied before `-m` selects (hence tryfirst).

    A live test in the wrong place stops the run. A test that reaches the
    database is marked `db`, so `-m "not db"` runs the rest with no Postgres
    at all. And the two suites never mix (#176): by default every live test is
    skipped, so `make check` and CI spend nothing; with --live only the live
    tests run, so `make test-live` spends nothing on the rest."""
    wrong = [
        item.nodeid for item in items if misplaced(bool(item.get_closest_marker(LIVE)), item.path)
    ]
    if wrong:
        raise pytest.UsageError(
            f"a test marked `{LIVE}` belongs in backend/tests/live/, and only those do: "
            + ", ".join(wrong)
        )
    for item in items:
        if DATABASE_FIXTURE in getattr(item, "fixturenames", ()):
            item.add_marker(DB)
    if config.getoption("--live"):
        deselected = [item for item in items if not item.get_closest_marker(LIVE)]
        items[:] = [item for item in items if item.get_closest_marker(LIVE)]
        config.hook.pytest_deselected(items=deselected)
        return
    skip = pytest.mark.skip(reason="live: calls the real APIs - run `make test-live`")
    for item in items:
        if item.get_closest_marker(LIVE):
            item.add_marker(skip)


@pytest.hookimpl
def pytest_terminal_summary(terminalreporter, config):
    """pytest-randomly shuffles the order on every run (#206), so a failure that
    depends on it needs the seed to come back - and `-q` hides the header that
    carries it. `-p no:randomly` runs in file order."""
    seed = getattr(config.option, "randomly_seed", None)
    if isinstance(seed, int):
        terminalreporter.write_line(
            f"test order: seed {seed}; replay it with `make back-test ARGS=--randomly-seed={seed}`"
        )


@pytest.fixture(autouse=True)
def disable_rate_limiter():
    """Disable the slowapi limiter during tests: the fast-running suite would
    otherwise trip the global per-second limit and flake. The tests about the
    limiter turn it back on for themselves (test_core/test_rate_limiter.py)."""
    from backend.core.rate_limiter import limiter

    previous = limiter.enabled
    limiter.enabled = False
    yield
    limiter.enabled = previous
