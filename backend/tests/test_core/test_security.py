"""The app's own JWT: what it signs, it verifies, and nothing else (#171).

The library moved from python-jose to PyJWT. Tokens already in students' hands
were signed by python-jose, and a deploy must not sign them out, so one of them
is kept here verbatim and must keep verifying.
"""

from datetime import timedelta

import pytest
from fastapi import HTTPException

from backend.core import security
from backend.core.config import settings

SECRET = "a-secret-signed-before-the-switch-to-pyjwt"

# Signed by python-jose 3.5.0 with SECRET: sub test_google_id_123, the app's
# issuer and audience, exp 2100-01-01.
JOSE_TOKEN = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJzdWIiOiJ0ZXN0X2dvb2dsZV9pZF8xMjMiLCJpc3MiOiJodHRwczovL2dvYWxzZ2V0dGVyLm9yZy9hcGkvdjEi"
    "LCJhdWQiOiJodHRwczovL2dvYWxzZ2V0dGVyLm9yZy9hcGkvdjEiLCJleHAiOjQxMDI0NDQ4MDB9."
    "pczdGXbrXyKUECabuG5uCO48qpkrplyTyQZ2y_iLOcI"
)


@pytest.fixture(autouse=True)
def secret(monkeypatch):
    monkeypatch.setattr(settings, "SECRET_KEY", SECRET)


def rejected(token: str) -> bool:
    try:
        security.verify_token(token)
    except HTTPException as err:
        return err.status_code == 401
    return False


def test_a_token_signed_before_the_switch_still_verifies():
    assert security.verify_token(JOSE_TOKEN)["sub"] == "test_google_id_123"


def test_a_token_it_signs_verifies_with_its_claims():
    payload = security.verify_token(security.create_access_token({"sub": "abc"}))
    assert payload["sub"] == "abc"


def test_an_expired_token_is_rejected():
    assert rejected(security.create_access_token({"sub": "abc"}, timedelta(seconds=-1)))


def test_a_token_signed_with_another_key_is_rejected(monkeypatch):
    token = security.create_access_token({"sub": "abc"})
    monkeypatch.setattr(settings, "SECRET_KEY", "another-secret-of-thirty-two-bytes-or-more")
    assert rejected(token)


def test_a_tampered_token_is_rejected():
    header, _, signature = JOSE_TOKEN.split(".")
    forged = security.create_access_token({"sub": "someone_else"}).split(".")[1]
    assert rejected(f"{header}.{forged}.{signature}")


def test_an_unsigned_token_is_rejected():
    header = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0"  # {"alg":"none","typ":"JWT"}
    assert rejected(f"{header}.{JOSE_TOKEN.split('.')[1]}.")
