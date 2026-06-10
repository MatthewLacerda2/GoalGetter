import pytest

# Import all fixtures so pytest can discover them
pytest_plugins = [
    "backend.tests.fixtures.database",
    "backend.tests.fixtures.auth",
    "backend.tests.fixtures.users",
    "backend.tests.fixtures.clients",
]

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