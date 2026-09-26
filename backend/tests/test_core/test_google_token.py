"""Signing in with Google (#186): a token Google rejects answers 401, Google out
of reach answers 503, and neither hands the exception's text to the client."""

from unittest.mock import patch

import httpx
import pytest
from google.auth.exceptions import TransportError

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
