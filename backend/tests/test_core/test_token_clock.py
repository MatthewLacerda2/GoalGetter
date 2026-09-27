"""A token expires on the clock that signed it (#206).

`create_access_token` stamps `exp` from `clock.now()`, the app's one clock. PyJWT
checks `exp` against the machine's time, so a test that froze the app's clock
signed a token PyJWT judged on another: valid became expired, and expired valid.
"""

from datetime import UTC, datetime, timedelta
from unittest.mock import patch

import pytest
from fastapi import HTTPException

from backend.core import security

# Both far from the real now, so whichever clock is read decides the outcome.
PAST = datetime(2020, 3, 1, 12, tzinfo=UTC)
FUTURE = datetime(2040, 3, 1, 12, tzinfo=UTC)
LIFETIME = timedelta(minutes=30)


def verify_at(moment: datetime, token: str) -> dict:
    with patch("backend.core.clock.now", lambda: moment):
        return security.verify_token(token)


def sign_at(moment: datetime) -> str:
    with patch("backend.core.clock.now", lambda: moment):
        return security.create_access_token({"sub": "abc"}, LIFETIME)


def test_a_token_is_valid_inside_its_lifetime_on_a_frozen_clock():
    assert verify_at(PAST + LIFETIME / 2, sign_at(PAST))["sub"] == "abc"


def test_a_token_expires_when_the_frozen_clock_passes_its_lifetime():
    with pytest.raises(HTTPException) as raised:
        verify_at(FUTURE + LIFETIME + timedelta(seconds=1), sign_at(FUTURE))

    assert raised.value.status_code == 401
