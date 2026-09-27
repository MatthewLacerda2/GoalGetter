"""The live suite's bookkeeping: what a run cost, and when it cannot run (#176).

Every billed request is counted where all of them pass - the async side of the
Gemini `Client` that `gemini_configs.get_client` builds (#216), and the YouTube
Data API behind httpx -
and the total is printed at the end of the run, so a run's cost is a number and
not a guess. Link checks against ordinary web pages are counted apart: they
reach the network but nobody bills them.

**The count is also a ceiling** (#206). A live test makes one billed call - the
use case it names - unless its marker says otherwise (`live(calls=3)`), and a
test that bills more fails. So a loop, a retry storm or a use case that grew a
second call is a red run, not a larger bill nobody reads. A Gemini call that
raised is not billed and not counted against it; it is printed apart.
"""

from collections import Counter
from urllib.parse import urlsplit

import httpx
import pytest

from backend.core.config import settings
from backend.services.gemini.client import gemini_configs

CALLS: Counter[str] = Counter()

GEMINI_GENERATE = "Gemini generate_content"
GEMINI_EMBED = "Gemini embed_content"
GEMINI_FAILED = "Gemini calls that raised (not billed)"
YOUTUBE = "YouTube Data API"
LINK_CHECK = "link checks (not billed)"
UNBILLED = (GEMINI_FAILED, LINK_CHECK)

GEMINI_HOST = "generativelanguage.googleapis.com"


@pytest.fixture(scope="session", autouse=True)
def count_calls():
    real_client = gemini_configs.Client
    real_send = httpx.AsyncClient.send

    def client(*args, **kwargs):
        built = real_client(*args, **kwargs)
        models = built.aio.models
        generate, embed = models.generate_content, models.embed_content

        async def counted(name, call, *a, **kw):
            try:
                answer = await call(*a, **kw)
            except BaseException:
                CALLS[GEMINI_FAILED] += 1
                raise
            CALLS[name] += 1
            return answer

        async def counted_generate(*a, **kw):
            return await counted(GEMINI_GENERATE, generate, *a, **kw)

        async def counted_embed(*a, **kw):
            return await counted(GEMINI_EMBED, embed, *a, **kw)

        models.generate_content = counted_generate
        models.embed_content = counted_embed
        return built

    async def send(self, request, *args, **kwargs):
        url = urlsplit(str(request.url))
        if url.hostname == GEMINI_HOST:
            # Gemini's async client is an httpx.AsyncClient too (#216); its
            # calls are counted above, one per call, not here per request.
            return await real_send(self, request, *args, **kwargs)
        youtube = url.hostname == "www.googleapis.com" and url.path.startswith("/youtube/")
        CALLS[YOUTUBE if youtube else LINK_CHECK] += 1
        return await real_send(self, request, *args, **kwargs)

    gemini_configs.Client = client  # type: ignore[misc, assignment]  # the wrapper is the point
    httpx.AsyncClient.send = send
    try:
        yield
    finally:
        gemini_configs.Client = real_client  # type: ignore[misc]
        httpx.AsyncClient.send = real_send


def billed() -> int:
    return sum(n for name, n in CALLS.items() if name not in UNBILLED)


@pytest.fixture(autouse=True)
def within_budget(request, count_calls):
    """Fail the test that billed more calls than its use case makes."""
    allowed = request.node.get_closest_marker("live").kwargs.get("calls", 1)
    before = billed()
    yield
    spent = billed() - before
    assert spent <= allowed, f"billed {spent} calls; this use case makes {allowed}"


@pytest.fixture
def gemini_key():
    """Skip, with the reason, rather than fail on a machine with no key."""
    if not settings.GEMINI_API_KEY or settings.GEMINI_API_KEY == "test-key":
        pytest.skip("GEMINI_API_KEY is not set - nothing to call Gemini with")


@pytest.fixture
def youtube_key():
    if not settings.YOUTUBE_API_KEY:
        pytest.skip("YOUTUBE_API_KEY is not set - nothing to call YouTube with")


@pytest.hookimpl
def pytest_terminal_summary(terminalreporter, config):
    if not config.getoption("--live"):
        return
    terminalreporter.section("live suite: calls made")
    for name in (GEMINI_GENERATE, GEMINI_EMBED, YOUTUBE, GEMINI_FAILED, LINK_CHECK):
        terminalreporter.write_line(f"{name:<38} {CALLS[name]}")
    terminalreporter.write_line(f"{'billed calls in total':<38} {billed()}")
