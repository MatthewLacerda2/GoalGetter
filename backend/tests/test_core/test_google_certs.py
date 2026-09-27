"""Signing in downloads Google's certificates once per the lifetime Google gives
them, not once per sign-in (#258).

The real verification path runs end to end - google-auth fetching the keys,
checking an RS256 signature, the audience and the issuer - with only the HTTP
call underneath it replaced, so what is counted is what would leave the machine.
"""

import io
import json
import time
from datetime import timedelta
from unittest.mock import patch

import jwt
import pytest
import requests
import urllib3
from cryptography.hazmat.primitives.asymmetric import rsa
from requests.adapters import HTTPAdapter

from backend.core import clock, google_certs, security
from backend.core.config import settings
from backend.core.security import verify_google_token

KEY = rsa.generate_private_key(public_exponent=65537, key_size=2048)
KID = "test-key"
# Pinned, not read from the environment: CI has no client id, and a token with an
# empty audience is one google-auth rejects.
CLIENT_ID = "goalgetter-test.apps.googleusercontent.com"
JWKS = {
    "keys": [
        {
            **jwt.algorithms.RSAAlgorithm.to_jwk(KEY.public_key(), as_dict=True),
            "kid": KID,
            "use": "sig",
            "alg": "RS256",
        }
    ]
}


@pytest.fixture(autouse=True)
def nothing_kept_yet(monkeypatch):
    """The cache lives as long as the process; each test starts without it."""
    monkeypatch.setattr(settings, "GOOGLE_CLIENT_ID", CLIENT_ID)
    monkeypatch.setattr(security, "GOOGLE_CERTS", google_certs.CachedGoogleCerts())


def google_id_token(sub: str) -> str:
    now = int(time.time())
    claims = {
        "iss": "https://accounts.google.com",
        "aud": CLIENT_ID,
        "sub": sub,
        "email": f"{sub}@example.com",
        "iat": now,
        "exp": now + 600,
    }
    return jwt.encode(claims, KEY, algorithm="RS256", headers={"kid": KID})


def google_serves_certs(cache_control: str, age: int = 0):
    """Replaces the HTTP call google-auth makes; returns the list of URLs fetched."""
    fetched: list[str] = []

    def request(_session, method, url, **_kwargs):
        fetched.append(url)
        # Lower-case names, as HTTP/2 sends them: headers are case-insensitive.
        answer = urllib3.HTTPResponse(
            body=io.BytesIO(json.dumps(JWKS).encode()),
            headers={"cache-control": cache_control, "age": str(age)},
            status=200,
            preload_content=False,
        )
        return HTTPAdapter().build_response(requests.Request(method, url).prepare(), answer)

    return fetched, patch.object(requests.Session, "request", request)


async def test_two_sign_ins_within_max_age_fetch_the_certificates_once():
    fetched, google = google_serves_certs("public, max-age=20000, must-revalidate")
    with google:
        first = await verify_google_token(google_id_token("ana"))
        second = await verify_google_token(google_id_token("bruno"))

    assert (first["sub"], second["sub"]) == ("ana", "bruno")
    assert len(fetched) == 1


async def test_the_certificates_are_fetched_again_once_max_age_less_age_has_passed():
    """Google's `Age` counts against its `max-age`: 20000 - 19000 leaves 1000 seconds."""
    fetched, google = google_serves_certs("public, max-age=20000", age=19000)
    start = clock.now()
    with google:
        await verify_google_token(google_id_token("ana"))
        with patch.object(clock, "now", return_value=start + timedelta(seconds=999)):
            await verify_google_token(google_id_token("ana"))
        assert len(fetched) == 1
        with patch.object(clock, "now", return_value=start + timedelta(seconds=1001)):
            await verify_google_token(google_id_token("ana"))

    assert len(fetched) == 2


async def test_certificates_served_without_max_age_are_not_kept():
    fetched, google = google_serves_certs("no-cache")
    with google:
        await verify_google_token(google_id_token("ana"))
        await verify_google_token(google_id_token("ana"))

    assert len(fetched) == 2
