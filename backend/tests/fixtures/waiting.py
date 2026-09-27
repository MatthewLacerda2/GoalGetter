"""The default suite never waits for real (#206).

Every wait the app makes is injected or configurable - the retry's `sleep`, the
budgets' delays, the nightly loop's `asyncio.sleep` - so a test can assert how
long something *would* wait without spending it. That is only true until a test
forgets one: two endpoint tests once rode `REQUEST_BUDGET`'s real half second on
every run, and nothing said so but a `--durations` read by hand.

So a positive `asyncio.sleep` or `time.sleep` raises, and is recorded, the way
`network.py` treats a connection: the per-test check fails the test that tried,
whoever swallowed the exception. `asyncio.sleep(0)` - yielding to the loop - is
not a wait and passes. A test that needs to wait "until cancelled" waits on
something that never happens (`asyncio.Event().wait()`), not on a long sleep.

Installed on import, so a `sleep` a module binds at import time (a default
argument, `from asyncio import sleep`) is already the guarded one. The live
suite puts the real ones back: there, a retry's wait is part of the call.
"""

import asyncio
import time

import pytest

SLEEPS: list[float] = []


class RealSleepInDefaultSuite(RuntimeError):
    """Not a CancelledError or a TimeoutError: code under test handles those."""


def refuse(delay: float):
    SLEEPS.append(delay)
    raise RealSleepInDefaultSuite(
        f"the default suite tried to wait {delay}s for real. Inject the wait "
        "(`call_with_retry(..., sleep=...)`, a budget with first_delay=0) or patch it."
    )


real_async_sleep, real_sleep = asyncio.sleep, time.sleep


async def guarded_async_sleep(delay, result=None):
    if delay > 0:
        refuse(delay)
    return await real_async_sleep(delay, result)


def guarded_sleep(delay):
    if delay > 0:
        refuse(delay)
    return real_sleep(delay)


def install():
    asyncio.sleep = asyncio.tasks.sleep = guarded_async_sleep
    time.sleep = guarded_sleep


def uninstall():
    asyncio.sleep = asyncio.tasks.sleep = real_async_sleep
    time.sleep = real_sleep


install()


@pytest.hookimpl
def pytest_configure(config):
    if config.getoption("--live"):
        uninstall()


@pytest.hookimpl
def pytest_unconfigure(config):
    uninstall()


@pytest.fixture(scope="session")
def sleeps():
    """Every real wait a test asked for. Empty for the whole default run."""
    return SLEEPS


@pytest.fixture(autouse=True)
def no_real_sleep(sleeps):
    """Fail the test that tried, even when the code under test ate the error."""
    sleeps.clear()
    yield
    tried = list(sleeps)
    sleeps.clear()
    assert not tried, f"this test waited for real: {tried} seconds"
