"""Every Gemini use case reads a recorded answer through its real parse path (#207).

The rest of the default suite replaces a use case whole, or hands the shared
call an answer built from the schema it is about to parse - so the step that
turns what Gemini sent into what the caller gets never ran against anything
Gemini sends. Here the only thing replaced is the client: the use case builds
its real prompt, the SDK's own `GenerateContentResponse` carries the recorded
answer, and the use case's schema parses it.

The cases are `make gemini`'s own (`backend/tools/gemini_cli.py`), which a
default-suite test already holds to "every function that calls Gemini" - so a
new use case fails here until it brings a recording.
"""

import dataclasses
import inspect
import json

import pytest
from pydantic import BaseModel

from backend.tests.fixtures.captured import GEMINI_RESPONSES, recorded
from backend.tests.fixtures.gemini_client import fake_gemini
from backend.tools.gemini_cli import USE_CASES


def plain(value):
    """The result as JSON-able data, whatever the use case returns."""
    if isinstance(value, BaseModel):
        return value.model_dump(mode="json")
    if dataclasses.is_dataclass(value) and not isinstance(value, type):
        return plain(dataclasses.asdict(value))
    if isinstance(value, dict):
        return {key: plain(item) for key, item in value.items()}
    if isinstance(value, list | tuple):
        return [plain(item) for item in value]
    return value


def said(value, key: str | None = None) -> set[tuple[str | None, str]]:
    """Every string in a JSON value, with the field it sits under - so a use
    case that swaps two fields loses both pairs even though it kept both texts."""
    if isinstance(value, str):
        return {(key, value)}
    if isinstance(value, dict):
        return {pair for name, item in value.items() for pair in said(item, name)}
    if isinstance(value, list):
        return {pair for item in value for pair in said(item, key)}
    return set()


def test_every_use_case_has_a_recording_and_every_recording_a_use_case():
    names = {case.name for case in USE_CASES}

    assert {path.stem for path in GEMINI_RESPONSES.glob("*.json")} == names


@pytest.mark.parametrize("case", USE_CASES, ids=lambda case: case.name)
async def test_the_recorded_answer_parses_into_what_the_caller_gets(case):
    calls = recorded(case.name)
    returns = inspect.signature(case.call).return_annotation

    with fake_gemini(*calls) as gemini:
        result = await case.call(*case.build(list(case.sample)))

    assert isinstance(result, returns), f"{case.name} answered {type(result).__name__}"
    assert len(gemini.calls) == len(calls)  # each recorded call asked once, none retried
    lost = said(json.loads(calls[-1].text)) - said(plain(result))
    assert not lost, f"{case.name} lost or moved what Gemini said: {lost}"
