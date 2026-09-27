"""The one typed call every use case makes (#216).

`generate` answers the schema it was given; an answer with nothing usable in it
is `GeminiNoAnswer`, never a `ValidationError`; the client is one, not one per
call; and nothing outside the client package reaches the SDK on its own.
"""

import asyncio
from types import SimpleNamespace

import pytest
from google.genai import Client

from backend.services.gemini.client import gemini_call, gemini_configs
from backend.services.gemini.client.gemini_call import GeminiNoAnswer, generate
from backend.services.gemini.onboarding.schema import GeminiGoalValidation
from backend.tests.fixtures.code import modules_under
from backend.tests.fixtures.gemini_client import BLOCKED, HANG, answer, fake_gemini

CLIENT_PACKAGE = "backend.services.gemini.client"

VALID = GeminiGoalValidation(makes_sense=True, is_harmless=True, is_achievable=True, reasoning="ok")


async def test_the_answer_comes_back_as_the_schema_asked_for():
    with fake_gemini(answer(VALID)) as gemini:
        result = await generate("gemini-test", "Is this a goal?", GeminiGoalValidation)

    assert result == VALID
    (call,) = gemini.calls
    assert call.model == "gemini-test"
    assert call.config.response_schema == GeminiGoalValidation.model_json_schema()


async def test_a_blocked_prompt_is_a_typed_error_asked_once():
    """`model_validate_json(None)` was a ValidationError, and a bare 500"""
    with fake_gemini(BLOCKED) as gemini, pytest.raises(GeminiNoAnswer) as raised:
        await generate("gemini-test", "anything", GeminiGoalValidation)

    assert "SAFETY" in raised.value.reason
    assert len(gemini.calls) == 1


async def test_an_empty_candidate_is_a_typed_error():
    empty = SimpleNamespace(
        text="", candidates=[SimpleNamespace(finish_reason="MAX_TOKENS")], prompt_feedback=None
    )

    with fake_gemini(empty), pytest.raises(GeminiNoAnswer) as raised:
        await generate("gemini-test", "anything", GeminiGoalValidation)

    assert "MAX_TOKENS" in raised.value.reason


async def test_text_that_is_not_the_schema_is_a_typed_error():
    with fake_gemini(SimpleNamespace(text='{"makes_sense": tr')), pytest.raises(GeminiNoAnswer):
        await generate("gemini-test", "anything", GeminiGoalValidation)


async def test_a_hung_call_fails_on_its_deadline():
    with fake_gemini(HANG) as gemini, pytest.raises(TimeoutError):
        await asyncio.wait_for(generate("gemini-test", "anything", GeminiGoalValidation), 1)

    assert len(gemini.calls) == 2


async def test_one_client_serves_every_call(monkeypatch):
    built = []

    def client(**kw):
        built.append(kw)
        return object()

    monkeypatch.setattr(gemini_configs, "Client", client)

    first, second = gemini_configs.get_client(), gemini_configs.get_client()

    assert first is second
    assert len(built) == 1


async def test_the_shared_call_speaks_the_sdks_async_api(monkeypatch):
    """The real SDK builds the request and is stopped at its transport, so a
    change in google-genai's async surface turns this red, not production"""
    sent = []

    async def transport(http_method, path, request_dict, http_options=None):
        sent.append(path)
        raise ConnectionAbortedError

    client = Client(api_key="offline")
    monkeypatch.setattr(client._api_client, "async_request", transport)
    monkeypatch.setattr(gemini_configs, "get_client", lambda: client)

    with pytest.raises(ConnectionAbortedError):
        await generate("gemini-test", "Is this a goal?", GeminiGoalValidation)

    assert sent == ["models/gemini-test:generateContent"]


def test_nothing_outside_the_client_reaches_the_sdk():
    """No use case holds a client of its own (#216): only the client package
    touches the SDK's `Client`, `get_client`, or the module that builds it."""
    doors = (Client, gemini_configs.get_client, gemini_configs)
    reaching = {
        module.__name__
        for module in modules_under("services") + modules_under("api")
        if any(value is door for value in vars(module).values() for door in doors)
    }

    assert {name for name in reaching if not name.startswith(CLIENT_PACKAGE)} == set()
    assert gemini_call.__name__ in reaching
