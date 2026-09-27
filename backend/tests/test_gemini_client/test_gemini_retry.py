"""The Gemini retry policy: what is repeated, what is not, how often, and for
how long.

Every test counts attempts instead of assuming them. The waiting is either the
injected `sleep`, which records a delay and returns, or a budget whose delays
are zeroed - so the attempt counts are the real ones and the file still runs in
milliseconds. A deadline is tested with a deadline of a few milliseconds.
"""

import asyncio

import httpx
import pytest
from fastapi import HTTPException
from google.genai.errors import APIError

from backend.services.gemini.client import gemini_guard
from backend.services.gemini.client.gemini_retry import (
    BACKGROUND_BUDGET,
    REQUEST_BUDGET,
    RetryBudget,
    call_with_retry,
)
from backend.tests.fixtures.gemini_client import HANG, api_error

TINY = 0.01


class Recorder:
    """A fake billed call: raises or returns each outcome in turn (the last one
    repeats forever), and counts how many times it was asked. `HANG` never
    returns."""

    def __init__(self, *outcomes):
        self.outcomes = list(outcomes)
        self.calls = 0

    async def __call__(self):
        self.calls += 1
        outcome = self.outcomes[min(self.calls - 1, len(self.outcomes) - 1)]
        if outcome is HANG:
            await asyncio.sleep(3600)
        if isinstance(outcome, BaseException):
            raise outcome
        return outcome

    async def use_case(self):
        """The same call as a use case makes it: through `call_with_retry`,
        on whatever budget the caller set."""
        return await call_with_retry(self, "test")


class Clock:
    """The injected wait: records what it was asked for and never sleeps."""

    def __init__(self):
        self.delays = []

    async def __call__(self, delay):
        self.delays.append(delay)


@pytest.fixture
def no_waiting(monkeypatch):
    """Keep both entry points' attempt counts, drop their delays to zero and
    their deadlines to a few milliseconds."""
    for name in ("REQUEST_BUDGET", "BACKGROUND_BUDGET"):
        budget = getattr(gemini_guard, name)
        monkeypatch.setattr(
            gemini_guard, name, RetryBudget(attempts=budget.attempts, first_delay=0, timeout=TINY)
        )


@pytest.mark.asyncio
async def test_transient_failure_then_success():
    call, clock = Recorder(api_error(503), "answer"), Clock()

    result = await call_with_retry(call, "test", budget=BACKGROUND_BUDGET, sleep=clock)

    assert result == "answer"
    assert call.calls == 2
    assert clock.delays == [BACKGROUND_BUDGET.first_delay]


@pytest.mark.asyncio
async def test_a_call_that_never_landed_is_retried():
    call, clock = Recorder(httpx.ConnectTimeout("upstream gone"), "answer"), Clock()

    assert await call_with_retry(call, "test", budget=REQUEST_BUDGET, sleep=clock) == "answer"
    assert call.calls == 2


@pytest.mark.asyncio
@pytest.mark.parametrize("code", [400, 401, 402, 403, 404])
async def test_permanent_failure_is_not_retried(code):
    """Depleted credit (402), the key, a rejected request: asked once, then raised."""
    call, clock = Recorder(api_error(code)), Clock()

    with pytest.raises(APIError):
        await call_with_retry(call, "test", budget=BACKGROUND_BUDGET, sleep=clock)

    assert call.calls == 1
    assert clock.delays == []


@pytest.mark.asyncio
async def test_a_bug_in_our_code_is_not_retried():
    call = Recorder(ValueError("bad schema"))

    with pytest.raises(ValueError):
        await call_with_retry(call, "test", budget=BACKGROUND_BUDGET, sleep=Clock())

    assert call.calls == 1


@pytest.mark.asyncio
async def test_budget_is_bounded_and_backs_off():
    call, clock = Recorder(api_error(503)), Clock()

    with pytest.raises(APIError):
        await call_with_retry(call, "test", budget=BACKGROUND_BUDGET, sleep=clock)

    assert call.calls == BACKGROUND_BUDGET.attempts == 4
    assert clock.delays == [2.0, 4.0, 8.0]


@pytest.mark.asyncio
async def test_a_waiting_user_gets_the_shorter_budget():
    call, clock = Recorder(api_error(429)), Clock()

    with pytest.raises(APIError):
        await call_with_retry(call, "test", budget=REQUEST_BUDGET, sleep=clock)

    assert call.calls == REQUEST_BUDGET.attempts == 2
    assert sum(clock.delays) < 1.0


@pytest.mark.asyncio
@pytest.mark.parametrize("code", [402, 429])
async def test_request_surfaces_geminis_status_code(no_waiting, code):
    call = Recorder(api_error(code))

    with pytest.raises(HTTPException) as raised:
        await gemini_guard.run_gemini(call.use_case)

    assert raised.value.status_code == code


@pytest.mark.asyncio
async def test_request_retries_then_answers(no_waiting):
    call = Recorder(api_error(503), "reply")

    assert await gemini_guard.run_gemini(call.use_case) == "reply"
    assert call.calls == 2


@pytest.mark.asyncio
async def test_unreachable_gemini_is_a_504(no_waiting):
    call = Recorder(httpx.ConnectError("no route"))

    with pytest.raises(HTTPException) as raised:
        await gemini_guard.run_gemini(call.use_case)

    assert raised.value.status_code == 504
    assert call.calls == 2


@pytest.mark.asyncio
async def test_background_work_raises_the_error_unchanged(no_waiting):
    call = Recorder(api_error(500))

    with pytest.raises(APIError) as raised:
        await gemini_guard.run_gemini_background(call.use_case)

    assert not isinstance(raised.value, HTTPException)
    assert call.calls == 4


@pytest.mark.asyncio
async def test_a_call_that_hangs_past_its_deadline_fails():
    """#216: nothing bounded a call before, and a hung one held its worker."""
    call, clock = Recorder(HANG), Clock()
    budget = RetryBudget(attempts=2, first_delay=0, timeout=TINY)

    with pytest.raises(TimeoutError):
        await asyncio.wait_for(call_with_retry(call, "test", budget=budget, sleep=clock), 1)

    assert call.calls == 2


@pytest.mark.asyncio
async def test_a_slow_call_is_asked_again_and_can_answer():
    call = Recorder(HANG, "answer")
    budget = RetryBudget(attempts=2, first_delay=0, timeout=TINY)

    assert await call_with_retry(call, "test", budget=budget, sleep=Clock()) == "answer"


@pytest.mark.asyncio
async def test_a_request_past_its_deadline_is_a_504(no_waiting):
    call = Recorder(HANG)

    with pytest.raises(HTTPException) as raised:
        await gemini_guard.run_gemini(call.use_case)

    assert raised.value.status_code == 504
    assert call.calls == REQUEST_BUDGET.attempts


@pytest.mark.asyncio
@pytest.mark.parametrize("code", [401, 403])
async def test_a_refused_key_is_never_a_401_to_the_app(no_waiting, code):
    """The app reads a 401 as "you are signed out"; our key is not his session"""
    with pytest.raises(HTTPException) as raised:
        await gemini_guard.run_gemini(Recorder(api_error(code)).use_case)

    assert raised.value.status_code == 502


@pytest.mark.asyncio
async def test_the_budget_is_the_callers(no_waiting):
    """A use case does not say how hard to try: the entry point it runs in does"""
    request, background = Recorder(api_error(503)), Recorder(api_error(503))

    with pytest.raises(HTTPException):
        await gemini_guard.run_gemini(request.use_case)
    with pytest.raises(APIError):
        await gemini_guard.run_gemini_background(background.use_case)

    assert (request.calls, background.calls) == (2, 4)
