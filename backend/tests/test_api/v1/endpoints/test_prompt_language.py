"""Every endpoint that calls Gemini hands it the student's language (#173).

The onboarding endpoints are public, so there is no student row: they read the
`X-Student-Language` header (#172), and without one the language his prompt is
written in. The tutor reads `students.language`.
"""

from unittest.mock import patch

import pytest

from backend.core.language import Language
from backend.services.gemini.chat.schema import GeminiChatResponse
from backend.services.gemini.onboarding.schema import (
    GeminiGoalValidation,
    GeminiOnboardingQuestionsResponse,
    GeminiStudyPlan,
)

GOALS = "backend.api.v1.endpoints.goals"
VALID = GeminiGoalValidation(makes_sense=True, is_harmless=True, is_achievable=True, reasoning="x")
NONE = GeminiOnboardingQuestionsResponse(questions=[])
PLAN = GeminiStudyPlan(goal_name="Xadrez", description="Aberturas.")


async def onboarding_languages(client, prompt: str, headers: dict) -> list[Language]:
    """The language each onboarding call was given, in order."""
    with (
        patch(GOALS + ".get_prompt_validation", return_value=VALID) as validate,
        patch(GOALS + ".generate_onboarding_questions", return_value=NONE) as generate,
        patch(GOALS + ".generate_study_plan", return_value=PLAN) as plan,
    ):
        await client.post(
            "/api/v1/goals/objective-questions", json={"prompt": prompt}, headers=headers
        )
        await client.post(
            "/api/v1/goals/study-plan", json={"prompt": prompt, "answers": []}, headers=headers
        )
    return [call.call_args.args[-1] for call in (validate, generate, plan)]


@pytest.mark.asyncio
async def test_onboarding_writes_in_the_language_the_app_sent(client):
    languages = await onboarding_languages(
        client, "I want to learn chess", {"X-Student-Language": "pt"}
    )

    assert languages == [Language.PORTUGUESE] * 3


@pytest.mark.asyncio
async def test_onboarding_without_the_header_writes_in_the_language_he_typed(client):
    languages = await onboarding_languages(client, "Quiero aprender ajedrez", {})

    assert languages == [Language.SPANISH] * 3


@pytest.mark.asyncio
async def test_the_tutor_writes_in_the_students_language(
    auth_client, test_db, test_user, goal_factory
):
    await goal_factory(test_user, active=True)
    test_user.language = "fr"
    await test_db.commit()
    reply = GeminiChatResponse(messages=["Oui."])

    with patch("backend.api.v1.endpoints.tutor.gemini_messages_generator", return_value=reply) as g:
        await auth_client.post("/api/v1/tutor/messages", json={"message": "How do I start?"})

    assert g.call_args.args[-1] == Language.FRENCH
