"""Signing in with Google (#186): a token Google rejects answers 401, Google out
of reach answers 503, and neither hands the exception's text to the client."""

import asyncio
import threading
from unittest.mock import patch

import httpx
import pytest
from google.auth.exceptions import TransportError

from backend.core.security import verify_google_token

SIGNUP = "/api/v1/auth/signup"
SECRET_TEXT = "internal detail 10.0.0.3"
ACCESS_TOKEN = {"Authorization": "Bearer ya29.an-access-token"}


@pytest.mark.asyncio
async def test_a_rejected_id_token_is_401_without_the_exception_text(client, mock_google_verify):
    mock_google_verify.side_effect = ValueError(SECRET_TEXT)
    response = await client.post(SIGNUP, headers={"Authorization": "Bearer a.b.c"})

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid Google token"


@pytest.mark.asyncio
async def test_google_certificates_out_of_reach_is_503(client, mock_google_verify):
    mock_google_verify.side_effect = TransportError(SECRET_TEXT)
    response = await client.post(SIGNUP, headers={"Authorization": "Bearer a.b.c"})

    assert response.status_code == 503
    assert SECRET_TEXT not in response.text


@pytest.mark.asyncio
async def test_a_rejected_access_token_is_401_without_the_exception_text(
    client, mock_google_verify
):
    mock_google_verify.side_effect = ValueError("Wrong number of segments")
    rejected = httpx.Response(401, text=SECRET_TEXT, request=httpx.Request("GET", "https://x"))
    with patch.object(httpx.AsyncClient, "get", return_value=rejected):
        response = await client.post(SIGNUP, headers=ACCESS_TOKEN)

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid Google token"


@pytest.mark.asyncio
async def test_google_userinfo_out_of_reach_is_503(client, mock_google_verify):
    mock_google_verify.side_effect = ValueError("Wrong number of segments")
    with patch.object(httpx.AsyncClient, "get", side_effect=httpx.ConnectError(SECRET_TEXT)):
        response = await client.post(SIGNUP, headers=ACCESS_TOKEN)

    assert response.status_code == 503
    assert SECRET_TEXT not in response.text


@pytest.mark.asyncio
async def test_verifying_an_id_token_leaves_the_event_loop_serving(mock_google_verify):
    """google-auth fetches Google's certificates with `requests`, which blocks: on
    the event loop, one slow sign-in would stall every other request (#210)."""
    loop_served = threading.Event()
    profile = mock_google_verify.return_value

    def slow_verify(*_args):
        # Returns only once the loop has run something else meanwhile - which it
        # cannot do while this call is holding it.
        assert loop_served.wait(timeout=2), "the event loop was blocked"
        return profile

    async def serve_someone_else():
        loop_served.set()

    mock_google_verify.side_effect = slow_verify
    user, _ = await asyncio.gather(verify_google_token("a.b.c"), serve_someone_else())

    assert user["sub"] == profile["sub"]
