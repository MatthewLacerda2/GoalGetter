"""Rate limits are counted per client address, not per proxy (#217).

In production the TCP peer is nginx for every request, so the address is the
`CF-Connecting-IP` Cloudflare's edge writes - trusted only from a private peer,
where our proxies live. A public peer is a client that skipped the tunnel.
"""

from unittest.mock import patch

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from starlette.requests import Request

from backend.core.rate_limiter import client_address, limiter
from backend.main import app
from backend.services.gemini.onboarding.schema import (
    GeminiGoalValidation,
    GeminiOnboardingQuestionsResponse,
)
from backend.tests.fixtures.routes import endpoints, with_made_up_ids

NGINX = "172.18.0.4"  # a peer on the compose network
OUTSIDER = "203.0.113.7"  # a peer with a public address: no proxy of ours
ONBOARDING = "/api/v1/goals/objective-questions"
ONBOARDING_LIMIT = 20  # per minute, goals.py
DEFAULT_LIMIT = 10  # per second, core/rate_limiter.py
# The routes that carry their own limit (goals.py), which replaces the default.
OWN_LIMIT = {
    ("POST", ONBOARDING),
    ("POST", "/api/v1/goals/study-plan"),
    ("POST", "/api/v1/goals"),
}
DEFAULTED = [endpoint for endpoint in endpoints() if endpoint not in OWN_LIMIT]
VALID = GeminiGoalValidation(makes_sense=True, is_harmless=True, is_achievable=True, reasoning="ok")


def request_from(peer: str | None, cf_ip: str | None = None) -> Request:
    headers = [(b"cf-connecting-ip", cf_ip.encode())] if cf_ip else []
    client = (peer, 50000) if peer else None
    return Request({"type": "http", "headers": headers, "client": client})


def test_behind_our_proxy_the_client_is_the_cloudflare_address():
    assert client_address(request_from(NGINX, "198.51.100.1")) == "198.51.100.1"
    assert client_address(request_from("127.0.0.1", "198.51.100.1")) == "198.51.100.1"


def test_a_public_peer_is_its_own_client_whatever_it_claims():
    assert client_address(request_from(OUTSIDER, "198.51.100.1")) == OUTSIDER


def test_what_is_not_an_address_falls_back_to_the_peer():
    assert client_address(request_from(NGINX, "not-an-ip")) == NGINX
    assert client_address(request_from(NGINX)) == NGINX
    assert client_address(request_from(None, "198.51.100.1")) == "unknown"


def test_an_ipv6_client_is_its_whole_64():
    one = client_address(request_from(NGINX, "2001:db8:1:2:aaaa::1"))
    same_subscriber = client_address(request_from(NGINX, "2001:db8:1:2:bbbb::9"))
    neighbour = client_address(request_from(NGINX, "2001:db8:1:3::1"))
    assert one == same_subscriber == "2001:db8:1:2::/64" != neighbour


@pytest.fixture
def rate_limited():
    """The suite runs with the limiter off (conftest); these tests are about it."""
    limiter.enabled = True
    limiter.reset()
    yield
    limiter.reset()


@pytest_asyncio.fixture
async def from_peer(rate_limited):
    """POSTs onboarding prompts as a given TCP peer, Gemini mocked."""
    questions = GeminiOnboardingQuestionsResponse(questions=[])
    with (
        patch(
            "backend.api.v1.endpoints.goals.get_prompt_validation",
            return_value=VALID,
            autospec=True,
        ),
        patch(
            "backend.api.v1.endpoints.goals.generate_onboarding_questions",
            return_value=questions,
            autospec=True,
        ),
    ):

        async def post(peer: str, cf_ip: str) -> int:
            transport = ASGITransport(app=app, client=(peer, 50000))
            async with AsyncClient(transport=transport, base_url="http://test") as ac:
                response = await ac.post(
                    ONBOARDING, json={"prompt": "guitar"}, headers={"CF-Connecting-IP": cf_ip}
                )
            return response.status_code

        yield post


async def test_two_students_behind_nginx_do_not_share_a_bucket(from_peer):
    first = [await from_peer(NGINX, "198.51.100.1") for _ in range(ONBOARDING_LIMIT + 1)]
    assert first == [200] * ONBOARDING_LIMIT + [429]
    assert await from_peer(NGINX, "198.51.100.2") == 200


async def test_a_forged_header_from_a_public_peer_does_not_pick_a_bucket(from_peer):
    forged = [await from_peer(OUTSIDER, f"198.51.100.{n}") for n in range(ONBOARDING_LIMIT + 1)]
    assert forged == [200] * ONBOARDING_LIMIT + [429]


def test_every_route_with_its_own_limit_still_exists():
    """A route renamed out of OWN_LIMIT would be swept below with the wrong limit"""
    assert set(OWN_LIMIT) <= set(endpoints())


@pytest.mark.usefixtures("rate_limited")
@pytest.mark.parametrize(("method", "path"), DEFAULTED, ids=[" ".join(e) for e in DEFAULTED])
async def test_every_route_refuses_past_the_default_limit(client, method, path):
    """Included routers too (#274): the limit is checked before the token or the
    body is, so whatever the first requests answer, the one past it is a 429"""
    url = with_made_up_ids(path)
    for _ in range(DEFAULT_LIMIT):
        await client.request(method, url)

    assert (await client.request(method, url)).status_code == 429
