"""Retry policy for Gemini calls.

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

Two budgets, because the caller decides how long a failure may take:

* `REQUEST_BUDGET` - a user is watching a spinner (the goal validation and the
  study plan, the tutor's reply). Two attempts, half a second apart: enough to ride
  out one blip, short enough that the request still answers. Gemini's own status
  code then reaches the client, so the app can say what happened.
* `BACKGROUND_BUDGET` - nobody is waiting (the goal-creation chain: resources,
  the student context, the first lesson bank). Four attempts backing off 2s, 4s,
  8s. If it still fails, the job logs and gives up: the nightly run is the real
  safety net, and a chain that failed tonight is filled tomorrow. That is why no
  budget here is measured in minutes.

The wait is injected (`sleep`) so the tests can assert the number of attempts
without spending a single real second.
"""

import asyncio
import logging
from collections.abc import Awaitable, Callable
from dataclasses import dataclass

import httpx
from fastapi.concurrency import run_in_threadpool
from google.genai.errors import APIError

logger = logging.getLogger(__name__)

# HTTP statuses that mean "not now" rather than "not ever": request timeout,
# rate limit, and the 5xx family Gemini returns when it is overloaded or down.
# 402 (no credit), 401/403 (the key) and 400/404 (the request) are absent on
# purpose - they answer the same way however often they are asked.
RETRYABLE_STATUS = frozenset({408, 429, 500, 502, 503, 504})

# The SDK talks HTTP over httpx, so a network failure arrives as one of these
# with no status code at all. Every one of them is "the call never landed".
RETRYABLE_EXCEPTIONS = (
    httpx.TimeoutException,
    httpx.ConnectError,
    httpx.ReadError,
    httpx.RemoteProtocolError,
)


@dataclass(frozen=True)
class RetryBudget:
    """How hard one caller may try. `first_delay` doubles on each further wait."""

    attempts: int
    first_delay: float


REQUEST_BUDGET = RetryBudget(attempts=2, first_delay=0.5)
BACKGROUND_BUDGET = RetryBudget(attempts=4, first_delay=2.0)


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


def _name(func: Callable) -> str:
    """Callables reach here as plain functions, but a partial or a test double
    has no `__name__` and a log line is not worth an AttributeError."""
    return getattr(func, "__name__", type(func).__name__)


async def call_with_retry(
    func: Callable,
    *args,
    budget: RetryBudget = REQUEST_BUDGET,
    sleep: Callable[[float], Awaitable[None]] = asyncio.sleep,
):
    """Run a blocking Gemini call off the event loop, retrying what can recover.

    Raises the last error once the budget is spent, or the first one if it was
    never worth repeating - callers translate it (an HTTPException for a
    request, a log line for a background job).
    """
    delay = budget.first_delay

    for attempt in range(1, budget.attempts + 1):
        try:
            return await run_in_threadpool(func, *args)
        except Exception as error:
            if not is_retryable(error):
                logger.warning(
                    "Gemini %s failed permanently (%s); not retrying",
                    _name(func),
                    _describe(error),
                )
                raise
            if attempt == budget.attempts:
                logger.warning(
                    "Gemini %s still failing (%s) after %d attempt(s); giving up",
                    _name(func),
                    _describe(error),
                    budget.attempts,
                )
                raise
            logger.info(
                "Gemini %s failed (%s) on attempt %d/%d; retrying in %.1fs",
                _name(func),
                _describe(error),
                attempt,
                budget.attempts,
                delay,
            )
            await sleep(delay)
            delay *= 2
