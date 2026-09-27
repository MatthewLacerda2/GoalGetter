"""The default suite never waits for real, and knows it (#206).

`fixtures/waiting.py` refuses every positive `asyncio.sleep` and `time.sleep`.
These tests are that claim checked from the outside - including the retry path,
whose default wait is half a second or more per retry.
"""

import asyncio
import time

import pytest
from google.genai.errors import APIError

from backend.services.gemini.client.gemini_retry import RetryBudget, call_with_retry
from backend.tests.fixtures.waiting import RealSleepInDefaultSuite


async def test_an_async_sleep_is_refused(sleeps):
    with pytest.raises(RealSleepInDefaultSuite):
        await asyncio.sleep(0.5)

    assert sleeps == [0.5]
    sleeps.clear()


def test_a_blocking_sleep_is_refused(sleeps):
    with pytest.raises(RealSleepInDefaultSuite):
        time.sleep(0.5)

    assert sleeps == [0.5]
    sleeps.clear()


async def test_yielding_to_the_loop_is_not_a_sleep(sleeps):
    await asyncio.sleep(0)

    assert sleeps == []


async def test_a_retry_left_on_its_real_wait_is_refused(sleeps):
    """What a test that forgets to inject the wait into `call_with_retry` meets."""
    attempts = 0

    async def overloaded():
        nonlocal attempts
        attempts += 1
        raise APIError(503, {"error": {"message": "overloaded", "status": "UNAVAILABLE"}})

    budget = RetryBudget(attempts=2, first_delay=0.5, timeout=1)
    with pytest.raises(RealSleepInDefaultSuite):
        await call_with_retry(overloaded, "test", budget=budget)

    assert (attempts, sleeps) == (1, [0.5])
    sleeps.clear()
