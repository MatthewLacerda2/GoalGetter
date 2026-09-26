"""The live suite's bookkeeping: what a run cost, and when it cannot run (#176).

Every billed request is counted where all of them pass - the Gemini `Client`
that `gemini_configs.get_client` builds, and the YouTube Data API behind httpx -
and the total is printed at the end of the run, so a run's cost is a number and
not a guess. Link checks against ordinary web pages are counted apart: they
reach the network but nobody bills them.
"""

from collections import Counter
from urllib.parse import urlsplit

import httpx
import pytest

from backend.core.config import settings
from backend.utils.gemini import gemini_configs

CALLS: Counter[str] = Counter()

GEMINI_GENERATE = "Gemini generate_content"
GEMINI_EMBED = "Gemini embed_content"
YOUTUBE = "YouTube Data API"
LINK_CHECK = "link checks (not billed)"


@pytest.fixture(scope="session", autouse=True)
def count_calls():
    real_client = gemini_configs.Client
    real_send = httpx.AsyncClient.send

    def client(*args, **kwargs):
        built = real_client(*args, **kwargs)
        generate, embed = built.models.generate_content, built.models.embed_content

        def counted_generate(*a, **kw):
            CALLS[GEMINI_GENERATE] += 1
            return generate(*a, **kw)

        def counted_embed(*a, **kw):
            CALLS[GEMINI_EMBED] += 1
            return embed(*a, **kw)

        built.models.generate_content = counted_generate
        built.models.embed_content = counted_embed
        return built

    async def send(self, request, *args, **kwargs):
        url = urlsplit(str(request.url))
        youtube = url.hostname == "www.googleapis.com" and url.path.startswith("/youtube/")
        CALLS[YOUTUBE if youtube else LINK_CHECK] += 1
        return await real_send(self, request, *args, **kwargs)

    gemini_configs.Client = client
    httpx.AsyncClient.send = send
    try:
        yield
    finally:
        gemini_configs.Client = real_client
        httpx.AsyncClient.send = real_send


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
    billed = sum(n for name, n in CALLS.items() if name != LINK_CHECK)
    terminalreporter.section("live suite: calls made")
    for name in (GEMINI_GENERATE, GEMINI_EMBED, YOUTUBE, LINK_CHECK):
        terminalreporter.write_line(f"{name:<28} {CALLS[name]}")
    terminalreporter.write_line(f"{'billed calls in total':<28} {billed}")
