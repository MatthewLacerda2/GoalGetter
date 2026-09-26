import pytest

# Import all fixtures so pytest can discover them
pytest_plugins = [
    "backend.tests.fixtures.database",
    "backend.tests.fixtures.auth",
    "backend.tests.fixtures.users",
    "backend.tests.fixtures.clients",
    "backend.tests.fixtures.goals",
    "backend.tests.fixtures.lessons",
    "backend.tests.fixtures.chat",
    "backend.tests.fixtures.network",
]

LIVE = "live"


@pytest.hookimpl
def pytest_addoption(parser):
    parser.addoption(
        "--live",
        action="store_true",
        help="run ONLY the tests marked live, against the real Gemini and YouTube "
        "APIs (spends real quota; `make test-live`)",
    )


@pytest.hookimpl
def pytest_configure(config):
    config.addinivalue_line(
        "markers",
        f"{LIVE}: calls the real Gemini/YouTube APIs and spends quota; skipped "
        "unless pytest runs with --live (#176)",
    )


@pytest.hookimpl
def pytest_collection_modifyitems(config, items):
    """Two suites that never mix (#176). By default every live test is skipped,
    so `make check` and CI spend nothing; with --live only the live tests run,
    so `make test-live` spends nothing on the rest."""
    if config.getoption("--live"):
        deselected = [item for item in items if not item.get_closest_marker(LIVE)]
        items[:] = [item for item in items if item.get_closest_marker(LIVE)]
        config.hook.pytest_deselected(items=deselected)
        return
    skip = pytest.mark.skip(reason="live: calls the real APIs - run `make test-live`")
    for item in items:
        if item.get_closest_marker(LIVE):
            item.add_marker(skip)


@pytest.fixture(autouse=True)
def disable_rate_limiter():
    """Disable the slowapi limiter during tests: the fast-running suite would
    otherwise trip the global per-second limit and flake. Rate limiting is
    verified against the running container, not in unit tests."""
    from backend.core.rate_limiter import limiter

    previous = limiter.enabled
    limiter.enabled = False
    yield
    limiter.enabled = previous
