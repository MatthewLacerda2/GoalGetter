from unittest.mock import patch

import pytest
from google.genai.errors import APIError
from sqlalchemy import select

from backend.api.v1.endpoints.tutor import HISTORY_WINDOW
from backend.models.chat_message import ChatMessage
from backend.models.student_context import StudentContext
from backend.services.gemini.chat.schema import GeminiChatResponse

ENDPOINT = "/api/v1/tutor/messages"
GEMINI = "backend.api.v1.endpoints.tutor.gemini_messages_generator"
REPLY = GeminiChatResponse(messages=["Short answer.", "Try it now."])


@pytest.mark.asyncio
async def test_send_persists_the_exchange(auth_client, test_db, test_user, goal_factory):
    goal = await goal_factory(test_user, active=True)
    with patch(GEMINI, return_value=REPLY):
        response = await auth_client.post(ENDPOINT, json={"message": "How do I start?"})

    assert response.status_code == 201
    body = response.json()
    assert body["prompt"] == "How do I start?"
    assert body["responses"] == ["Short answer.", "Try it now."]
    assert body["is_liked"] is False
    row = (
        await test_db.execute(select(ChatMessage).where(ChatMessage.id == body["id"]))
    ).scalar_one()
    assert (row.goal_id, row.tutor_responses) == (goal.id, ["Short answer.", "Try it now."])


@pytest.mark.asyncio
async def test_send_gives_gemini_the_window_oldest_first(
    auth_client, test_db, test_user, goal_factory, exchange_factory
):
    goal = await goal_factory(test_user, active=True)
    other_goal = await goal_factory(test_user, name="Chess")
    await exchange_factory(goal, count=HISTORY_WINDOW + 2)
    await exchange_factory(other_goal)
    test_db.add(
        StudentContext(
            student_id=test_user.id, goal_id=goal.id, state="beginner", metacognition="curious"
        )
    )
    await test_db.flush()
    with patch(GEMINI, return_value=REPLY) as gemini:
        await auth_client.post(ENDPOINT, json={"message": "next?"})

    history, contexts, name, description = gemini.call_args.args
    kept = range(2, HISTORY_WINDOW + 2)  # the two oldest fall out of the window
    expected = [t for i in kept for t in (("user", f"q{i}"), ("model", f"a{i}\nb{i}"))]
    assert [(m.role, m.message) for m in history] == expected + [("user", "next?")]
    assert [(c.state, c.metacognition) for c in contexts] == [("beginner", "curious")]
    assert (name, description) == (goal.name, goal.description)


@pytest.mark.asyncio
async def test_send_keeps_gemini_status_code(auth_client, test_db, test_user, goal_factory):
    await goal_factory(test_user, active=True)
    err = APIError.__new__(APIError)
    err.code, err.message = 429, "RESOURCE_EXHAUSTED"
    with patch(GEMINI, side_effect=err):
        response = await auth_client.post(ENDPOINT, json={"message": "hi"})
    assert response.status_code == 429
    assert (await test_db.execute(select(ChatMessage))).first() is None


@pytest.mark.asyncio
async def test_send_without_active_goal_is_404(auth_client, test_user, goal_factory):
    await goal_factory(test_user)
    with patch(GEMINI) as gemini:
        response = await auth_client.post(ENDPOINT, json={"message": "hi"})
    assert response.status_code == 404
    gemini.assert_not_called()
