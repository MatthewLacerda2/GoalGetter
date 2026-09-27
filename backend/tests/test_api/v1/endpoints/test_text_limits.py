"""Every text a client sends into a Gemini prompt has a ceiling (#217): an
over-long body is a 422, and Gemini is never called for it."""

from unittest.mock import patch

import pytest

from backend.schemas.text_limits import (
    GENERATED_DESCRIPTION_MAX_LENGTH,
    GENERATED_LINE_MAX_LENGTH,
    GOAL_PROMPT_MAX_LENGTH,
    ONBOARDING_ANSWERS_MAX_COUNT,
    TUTOR_MESSAGE_MAX_LENGTH,
)
from backend.services.gemini.chat.schema import GeminiChatResponse

GOALS_GEMINI = "backend.api.v1.endpoints.goals.run_gemini"
CHAIN = "backend.api.v1.endpoints.goals.kickoff_student_chain"
TUTOR_GEMINI = "backend.api.v1.endpoints.tutor.gemini_messages_generator"

ANSWER = {"question": "Experience?", "answer": "None"}
LONG_PROMPT = "x" * (GOAL_PROMPT_MAX_LENGTH + 1)
LONG_LINE = "x" * (GENERATED_LINE_MAX_LENGTH + 1)
COMMIT = {"prompt": "guitar", "answers": [ANSWER], "goal_name": "Guitar", "description": "Chords."}


@pytest.mark.parametrize(
    ("endpoint", "body"),
    [
        ("/api/v1/goals/objective-questions", {"prompt": LONG_PROMPT}),
        ("/api/v1/goals/study-plan", {"prompt": LONG_PROMPT, "answers": [ANSWER]}),
        (
            "/api/v1/goals/study-plan",
            {"prompt": "guitar", "answers": [ANSWER | {"answer": LONG_LINE}]},
        ),
        (
            "/api/v1/goals/study-plan",
            {"prompt": "guitar", "answers": [ANSWER | {"question": LONG_LINE}]},
        ),
        (
            "/api/v1/goals/study-plan",
            {"prompt": "guitar", "answers": [ANSWER] * (ONBOARDING_ANSWERS_MAX_COUNT + 1)},
        ),
    ],
)
async def test_an_over_long_onboarding_text_never_reaches_gemini(client, endpoint, body):
    with patch(GOALS_GEMINI, autospec=True) as gemini:
        response = await client.post(endpoint, json=body)
    assert response.status_code == 422
    gemini.assert_not_called()


@pytest.mark.parametrize(
    "override",
    [
        {"prompt": LONG_PROMPT},
        {"goal_name": LONG_LINE},
        {"description": "x" * (GENERATED_DESCRIPTION_MAX_LENGTH + 1)},
    ],
)
async def test_an_over_long_goal_is_not_stored_for_the_chain(auth_client, override):
    """POST /goals calls no Gemini itself, but what it stores is the chain's prompt"""
    with patch(CHAIN) as chain:
        response = await auth_client.post("/api/v1/goals", json=COMMIT | override)
    assert response.status_code == 422
    chain.assert_not_called()


async def test_an_over_long_tutor_message_never_reaches_gemini(
    auth_client, test_user, goal_factory
):
    await goal_factory(test_user, active=True)
    message = "x" * (TUTOR_MESSAGE_MAX_LENGTH + 1)
    with patch(TUTOR_GEMINI, autospec=True) as gemini:
        response = await auth_client.post("/api/v1/tutor/messages", json={"message": message})
    assert response.status_code == 422
    gemini.assert_not_called()


async def test_a_tutor_message_at_the_limit_is_answered(auth_client, test_user, goal_factory):
    await goal_factory(test_user, active=True)
    message = "x" * TUTOR_MESSAGE_MAX_LENGTH
    reply = GeminiChatResponse(messages=["Ok."])
    with patch(TUTOR_GEMINI, return_value=reply, autospec=True) as gemini:
        response = await auth_client.post("/api/v1/tutor/messages", json={"message": message})
    assert response.status_code == 201
    gemini.assert_called_once()
