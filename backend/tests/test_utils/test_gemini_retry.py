"""The Gemini retry policy: what is repeated, what is not, and how often.

Every test counts attempts instead of assuming them. The waiting is either the
injected `sleep`, which records a delay and returns, or a budget whose delays
are zeroed - so the attempt counts are the real ones and the file still runs in
milliseconds.
"""

import httpx
import pytest
from fastapi import HTTPException
from google.genai.errors import APIError

from backend.utils.gemini import gemini_guard
from backend.utils.gemini.gemini_retry import (
    BACKGROUND_BUDGET,
    REQUEST_BUDGET,
    RetryBudget,
    call_with_retry,
)


def api_error(code: int) -> APIError:
    return APIError(code, {"error": {"message": f"boom {code}", "status": "TEST"}})


class Recorder:
    """A fake Gemini call: raises or returns each outcome in turn (the last one
    repeats forever), and counts how many times it was asked."""

    def __init__(self, *outcomes):
        self.outcomes = list(outcomes)
        self.calls = 0

    def __call__(self, *args):
        self.calls += 1
        outcome = self.outcomes[min(self.calls - 1, len(self.outcomes) - 1)]
        if isinstance(outcome, BaseException):
            raise outcome
        return outcome


class Clock:
    """The injected wait: records what it was asked for and never sleeps."""

    def __init__(self):
        self.delays = []

    async def __call__(self, delay):
        self.delays.append(delay)


@pytest.fixture
def no_waiting(monkeypatch):
    """Keep both entry points' attempt counts, drop their delays to zero."""
    for name in ("REQUEST_BUDGET", "BACKGROUND_BUDGET"):
        budget = getattr(gemini_guard, name)
        monkeypatch.setattr(
            gemini_guard, name, RetryBudget(attempts=budget.attempts, first_delay=0)
        )


@pytest.mark.asyncio
async def test_transient_failure_then_success():
    call, clock = Recorder(api_error(503), "answer"), Clock()

    result = await call_with_retry(call, budget=BACKGROUND_BUDGET, sleep=clock)

    assert result == "answer"
    assert call.calls == 2
    assert clock.delays == [BACKGROUND_BUDGET.first_delay]


@pytest.mark.asyncio
async def test_a_call_that_never_landed_is_retried():
    call, clock = Recorder(httpx.ConnectTimeout("upstream gone"), "answer"), Clock()

    assert await call_with_retry(call, budget=REQUEST_BUDGET, sleep=clock) == "answer"
    assert call.calls == 2


@pytest.mark.asyncio
@pytest.mark.parametrize("code", [400, 401, 402, 403, 404])
async def test_permanent_failure_is_not_retried(code):
    """Depleted credit (402), the key, a rejected request: asked once, then raised."""
    call, clock = Recorder(api_error(code)), Clock()

    with pytest.raises(APIError):
        await call_with_retry(call, budget=BACKGROUND_BUDGET, sleep=clock)

    assert call.calls == 1
    assert clock.delays == []


@pytest.mark.asyncio
async def test_a_bug_in_our_code_is_not_retried():
    call = Recorder(ValueError("bad schema"))

    with pytest.raises(ValueError):
        await call_with_retry(call, budget=BACKGROUND_BUDGET, sleep=Clock())

    assert call.calls == 1


@pytest.mark.asyncio
async def test_budget_is_bounded_and_backs_off():
    call, clock = Recorder(api_error(503)), Clock()

    with pytest.raises(APIError):
        await call_with_retry(call, budget=BACKGROUND_BUDGET, sleep=clock)

    assert call.calls == BACKGROUND_BUDGET.attempts == 4
    assert clock.delays == [2.0, 4.0, 8.0]


@pytest.mark.asyncio
async def test_a_waiting_user_gets_the_shorter_budget():
    call, clock = Recorder(api_error(429)), Clock()

    with pytest.raises(APIError):
        await call_with_retry(call, budget=REQUEST_BUDGET, sleep=clock)

    assert call.calls == REQUEST_BUDGET.attempts == 2
    assert sum(clock.delays) < 1.0


@pytest.mark.asyncio
async def test_request_surfaces_geminis_status_code(no_waiting):
    call = Recorder(api_error(402))

    with pytest.raises(HTTPException) as raised:
        await gemini_guard.run_gemini(call)

    assert raised.value.status_code == 402
    assert call.calls == 1


@pytest.mark.asyncio
async def test_request_retries_then_answers(no_waiting):
    call = Recorder(api_error(503), "reply")

    assert await gemini_guard.run_gemini(call) == "reply"
    assert call.calls == 2


@pytest.mark.asyncio
async def test_unreachable_gemini_is_a_504(no_waiting):
    call = Recorder(httpx.ConnectError("no route"))

    with pytest.raises(HTTPException) as raised:
        await gemini_guard.run_gemini(call)

    assert raised.value.status_code == 504
    assert call.calls == 2


@pytest.mark.asyncio
async def test_background_work_raises_the_error_unchanged(no_waiting):
    call = Recorder(api_error(500))

    with pytest.raises(APIError) as raised:
        await gemini_guard.run_gemini_background(call)

    assert not isinstance(raised.value, HTTPException)
    assert call.calls == 4
