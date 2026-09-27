"""The API's errors come from one enum and answer one body (#214).

The app switches on `code`, so every way an error can leave the app - ours,
FastAPI's, Starlette's, slowapi's, a crash - must carry one.
"""

import logging

import pytest

from backend.core.errors.codes import ErrorCode
from backend.core.rate_limiter import limiter
from backend.main import app

SESSION = {
    "not_signed_in",
    "invalid_token",
    "student_no_longer_exists",
    "invalid_refresh_token",
    "invalid_google_token",
}
UPSTREAM_PREFIXES = ("gemini_", "google_")


def test_every_code_is_an_error_status_with_a_sentence():
    for code in ErrorCode:
        assert 400 <= code.status < 600, code
        assert code.sentence, code
        assert code.value == code.value.lower(), code


def test_no_two_members_share_a_code():
    """Enum aliases a repeated value silently: the second name would vanish."""
    assert len(ErrorCode.__members__) == len(list(ErrorCode))


def test_only_the_session_signs_him_out():
    """The app reads 401 as "your session ended" (#186)."""
    assert {c.value for c in ErrorCode if c.status == 401} == SESSION


def test_a_service_we_call_failing_is_always_our_5xx():
    upstream = [c for c in ErrorCode if c.value.startswith(UPSTREAM_PREFIXES)]
    assert upstream
    assert all(c.status >= 500 for c in upstream), upstream


def test_the_openapi_declares_the_body_and_every_code():
    schema = app.openapi()
    assert schema["components"]["schemas"]["ErrorCode"]["enum"] == [c.value for c in ErrorCode]
    responses = schema["paths"]["/api/v1/home"]["get"]["responses"]
    for status_range in ("4XX", "5XX"):
        body = responses[status_range]["content"]["application/json"]["schema"]
        assert body == {"$ref": "#/components/schemas/ErrorResponse"}


async def test_what_the_framework_refuses_carries_a_code(client):
    unknown = await client.get("/api/v1/nowhere")
    wrong_method = await client.patch("/api/v1/home")
    no_bearer = await client.get("/api/v1/home")

    assert (unknown.status_code, unknown.json()["code"]) == (404, "route_not_found")
    assert (wrong_method.status_code, wrong_method.json()["code"]) == (405, "method_not_allowed")
    assert (no_bearer.status_code, no_bearer.json()["code"]) == (401, "not_signed_in")
    assert no_bearer.headers["www-authenticate"] == "Bearer"


async def test_a_body_that_does_not_parse_names_the_field(client):
    response = await client.post("/api/v1/goals/objective-questions", json={})

    assert response.status_code == 422
    assert response.json() == {"code": "invalid_request", "detail": "body.prompt: Field required"}


async def test_a_4xx_is_not_logged_as_an_error(client, caplog):
    with caplog.at_level(logging.INFO, logger="backend.core.logging_middleware"):
        await client.get("/api/v1/nowhere")

    bodies = [r for r in caplog.records if r.getMessage().startswith("Error Body")]
    assert [r.levelno for r in bodies] == [logging.INFO]


@pytest.fixture
def rate_limited():
    """The suite runs with the limiter off (conftest); this test is about it."""
    limiter.enabled = True
    limiter.reset()
    yield
    limiter.reset()


@pytest.mark.usefixtures("rate_limited")
async def test_the_default_rate_limit_carries_a_code(client):
    """On a route of an included router, as every route but three was (#274)."""
    statuses = [(await client.get("/api/v1/me")).status_code for _ in range(11)]
    refused = await client.get("/api/v1/me")

    assert statuses[-1] == refused.status_code == 429
    assert refused.json()["code"] == "too_many_requests"
