import pytest
from typing import List
from backend.utils.envs import NUM_QUESTIONS_PER_LESSON
from backend.schemas.activity import MultipleChoiceActivityResponse, MultipleChoiceActivityEvaluationResponse
from backend.schemas.activity import MultipleChoiceQuestionAnswer, MultipleChoiceActivityEvaluationRequest

@pytest.mark.asyncio
async def test_take_multiple_choice_activity_success(auth_client, mock_gemini_multiple_choice_questions):
    """Test that the activities endpoint returns a valid response."""
    response = await auth_client.post("/api/v1/activities")
    assert response.status_code == 201
    
    activity_response = MultipleChoiceActivityResponse.model_validate(response.json())
    assert isinstance(activity_response, MultipleChoiceActivityResponse)
    assert len(activity_response.questions) >= NUM_QUESTIONS_PER_LESSON

@pytest.mark.asyncio
async def test_take_multiple_choice_activity_unauthorized(client):
    """Test that the activities endpoint returns 403 without token."""
    response = await client.post("/api/v1/activities")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_evaluate_multiple_choice_activity_success(auth_client, test_multiple_choice_questions):
    """Test that the evaluate activities endpoint returns a valid response."""
    answers = [MultipleChoiceQuestionAnswer(id=str(question.id), student_answer_index=0, seconds_spent=5) for question in test_multiple_choice_questions]
    request_body = MultipleChoiceActivityEvaluationRequest(answers=answers)
    
    response = await auth_client.post(
        "/api/v1/activities/evaluate",
        json=request_body.model_dump()
    )
    
    assert response.status_code == 201
    activity_response = MultipleChoiceActivityEvaluationResponse.model_validate(response.json())
    assert isinstance(activity_response, MultipleChoiceActivityEvaluationResponse)

@pytest.mark.asyncio
async def test_evaluate_multiple_choice_activity_unauthorized(client):
    """Test that the evaluate activities endpoint returns 403 without token."""
    response = await client.post("/api/v1/activities/evaluate")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_evaluate_multiple_choice_not_enough_questions(auth_client):
    """Test that the evaluate activities endpoint returns 400 without enough questions."""
    answers = [MultipleChoiceQuestionAnswer(id=f"id_{i}", student_answer_index= 0, seconds_spent=5) for i in range (2)]
    request_body = MultipleChoiceActivityEvaluationRequest(answers=answers)
    
    response = await auth_client.post(
        "/api/v1/activities/evaluate",
        json=request_body.model_dump()
    )
    
    assert response.status_code == 400
    assert response.json()["detail"] == "Amount of questions was too low."