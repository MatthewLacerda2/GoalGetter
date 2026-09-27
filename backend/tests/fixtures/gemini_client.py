"""A Gemini client that never leaves the process (#216).

Most tests replace a whole use case. These replace only the client every use
case shares, so the code under test is the real one - the prompt it builds, the
shared call's retries, its deadline, what it makes of an empty answer - and the
assertion can be on what Gemini would have been sent, or how many times.

`fake_gemini(*outcomes)` answers each call with the next outcome (the last one
repeats): a response, an exception to raise, or `HANG`, a call that never
returns. It also runs everything inside it on `FAST`, a budget with the request
budget's two attempts and no wait between them, so a retried call costs the
suite nothing.
"""

import asyncio
from contextlib import contextmanager
from types import SimpleNamespace
from unittest.mock import patch

from google.genai.errors import APIError
from pydantic import BaseModel

from backend.services.gemini.client.gemini_retry import RetryBudget, using_budget

CLIENT = "backend.services.gemini.client.gemini_configs.get_client"

HANG = object()

FAST = RetryBudget(attempts=2, first_delay=0, timeout=0.05)

# What Gemini sends for a prompt its safety filter refused: no text at all.
BLOCKED = SimpleNamespace(
    text=None, prompt_feedback=SimpleNamespace(block_reason="SAFETY"), candidates=[]
)


def answer(parsed: BaseModel) -> SimpleNamespace:
    """A response whose text is this model as JSON, as Gemini would send it."""
    return SimpleNamespace(text=parsed.model_dump_json())


def api_error(code: int) -> APIError:
    return APIError(code, {"error": {"message": f"boom {code}", "status": "TEST"}})


class FakeModels:
    """`client.aio.models`: records every call it is asked, answers in turn."""

    def __init__(self, outcomes):
        self.outcomes = list(outcomes)
        self.calls: list[SimpleNamespace] = []
        self.embedded: list = []

    async def generate_content(self, *, model, contents, config):
        self.calls.append(SimpleNamespace(model=model, contents=contents, config=config))
        outcome = self.outcomes[min(len(self.calls) - 1, len(self.outcomes) - 1)]
        if outcome is HANG:
            await asyncio.sleep(3600)
        if isinstance(outcome, BaseException):
            raise outcome
        return outcome

    async def embed_content(self, **kwargs):
        self.embedded.append(kwargs)
        raise AssertionError("this test did not expect an embedding")


@contextmanager
def fake_gemini(*outcomes, budget: RetryBudget = FAST):
    models = FakeModels(outcomes)
    client = SimpleNamespace(aio=SimpleNamespace(models=models))
    with patch(CLIENT, lambda: client), using_budget(budget):
        yield models
