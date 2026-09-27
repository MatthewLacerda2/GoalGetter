"""Retry and timeout policy for Gemini calls.

Gemini is not always there. A call can fail because the model is momentarily
overloaded, because the request timed out on the way, or because we went over a
per-minute rate limit - every one of those succeeds if we simply ask again.
Other failures never will: a depleted credit balance (this project's key
answered `402 RESOURCE_EXHAUSTED` on 2026-09-23), a key that is not a key, a
request the model rejects. Repeating those burns time and, worse, hides the
real reason behind a retry loop.

So the policy is a status-code allow-list (`RETRYABLE_STATUS`) plus the
transport failures that happen before any status code exists
(`RETRYABLE_EXCEPTIONS`). Everything else is raised on the first attempt.

**One attempt is one billed call** (#216). `call_with_retry` is handed a single
request to repeat, never a function that makes several: the resource search
makes two calls, and a 429 on the second one used to re-run the first (a
grounded search, the dearer of the two) along with it.

**Every attempt has a deadline** (`RetryBudget.timeout`). A call that hangs is
cancelled when it passes, and counts as a transport failure: asked again while
the budget lasts, then raised. Before #216 nothing bounded it, and a hung call
held its worker thread until the connection gave up on its own.

Two budgets, because the caller decides how long a failure may take:

* `REQUEST_BUDGET` - a user is watching a spinner (the goal validation and the
  study plan, the tutor's reply). Two attempts, half a second apart, 45 seconds
  each: enough to ride out one blip, and short enough that one call still
  answers inside the 100 seconds Cloudflare holds a request open. Gemini's own status code then reaches the
  client, so the app can say what happened.
* `BACKGROUND_BUDGET` - nobody is waiting (the goal-creation chain: resources,
  the student context, the first lesson bank). Four attempts backing off 2s, 4s,
  8s, two minutes each - a grounded search or an 18-exercise placement is slow,
  not broken. If it still fails, the job logs and gives up: the nightly run is
  the real safety net, and a chain that failed tonight is filled tomorrow.

The budget is not an argument of every use case: `using_budget` sets it for
whatever runs inside it (`gemini_guard.run_gemini` / `run_gemini_background`),
and `call_with_retry`, which every call goes through, reads it. A use case called
on its own - `make gemini`, the live suite - runs on the request budget.

The wait is injected (`sleep`) so the tests can assert the number of attempts
without spending a single real second.
"""

import asyncio
import logging
from collections.abc import Awaitable, Callable, Iterator
from contextlib import contextmanager
from contextvars import ContextVar
from dataclasses import dataclass

import httpx
from google.genai.errors import APIError

logger = logging.getLogger(__name__)

# HTTP statuses that mean "not now" rather than "not ever": request timeout,
# rate limit, and the 5xx family Gemini returns when it is overloaded or down.
# 402 (no credit), 401/403 (the key) and 400/404 (the request) are absent on
# purpose - they answer the same way however often they are asked.
RETRYABLE_STATUS = frozenset({408, 429, 500, 502, 503, 504})

# The SDK talks HTTP over httpx, so a network failure arrives as one of these
# with no status code at all. Every one of them is "the call never landed".
# `TimeoutError` is our own deadline passing (`asyncio.wait_for`).
RETRYABLE_EXCEPTIONS = (
    httpx.TimeoutException,
    httpx.ConnectError,
    httpx.ReadError,
    httpx.RemoteProtocolError,
    TimeoutError,
)


@dataclass(frozen=True)
class RetryBudget:
    """How hard one caller may try. `first_delay` doubles on each further wait;
    `timeout` is the seconds one attempt may take before it is cancelled."""

    attempts: int
    first_delay: float
    timeout: float


REQUEST_BUDGET = RetryBudget(attempts=2, first_delay=0.5, timeout=45.0)
BACKGROUND_BUDGET = RetryBudget(attempts=4, first_delay=2.0, timeout=120.0)

_budget: ContextVar[RetryBudget] = ContextVar("gemini_budget", default=REQUEST_BUDGET)


@contextmanager
def using_budget(budget: RetryBudget) -> Iterator[None]:
    """Every Gemini call made inside this block tries this hard."""
    token = _budget.set(budget)
    try:
        yield
    finally:
        _budget.reset(token)


def is_retryable(error: BaseException) -> bool:
    """Can this failure plausibly succeed if we ask again?"""
    if isinstance(error, RETRYABLE_EXCEPTIONS):
        return True
    if isinstance(error, APIError):
        return error.code in RETRYABLE_STATUS
    return False


def _describe(error: BaseException) -> str:
    if isinstance(error, APIError):
        return f"{error.code} {error.status}"
    return type(error).__name__


async def call_with_retry[R](
    call: Callable[[], Awaitable[R]],
    name: str,
    *,
    budget: RetryBudget | None = None,
    sleep: Callable[[float], Awaitable[None]] = asyncio.sleep,
) -> R:
    """Make one billed call under a deadline, retrying what can recover.

    `call` sends a fresh request each time it is called; `name` says which one
    in the log. The budget is the caller's (`using_budget`) unless one is given.
    Raises the last error once the budget is spent, or the first one if it was
    never worth repeating - callers translate it (an ApiError for a
    request, a log line for a background job).
    """
    budget = budget or _budget.get()
    delay = budget.first_delay
    attempt = 1

    while True:
        try:
            return await asyncio.wait_for(call(), budget.timeout)
        except Exception as error:
            if not is_retryable(error):
                logger.warning(
                    "Gemini %s failed permanently (%s); not retrying", name, _describe(error)
                )
                raise
            if attempt == budget.attempts:
                logger.warning(
                    "Gemini %s still failing (%s) after %d attempt(s); giving up",
                    name,
                    _describe(error),
                    budget.attempts,
                )
                raise
            logger.info(
                "Gemini %s failed (%s) on attempt %d/%d; retrying in %.1fs",
                name,
                _describe(error),
                attempt,
                budget.attempts,
                delay,
            )
            await sleep(delay)
            delay *= 2
            attempt += 1
