import pytest
from backend.schemas.assessment import SubjectiveQuestionsAssessmentResponse
from backend.utils.envs import NUM_QUESTIONS_PER_EVALUATION

@pytest.mark.asyncio
async def test_take_subjective_questions_assessment_success(authenticated_client_with_objective, mock_gemini_subjective_questions):
    """Test that the assessment endpoint returns a valid response."""
    
    client, access_token = authenticated_client_with_objective
    
    response = await client.post("/api/v1/assessments", headers={"Authorization": f"Bearer {access_token}"})
    
    assert response.status_code == 201
    
    assessment_response = SubjectiveQuestionsAssessmentResponse.model_validate(response.json())
    assert isinstance(assessment_response, SubjectiveQuestionsAssessmentResponse)
    assert len(assessment_response.questions) >= NUM_QUESTIONS_PER_EVALUATION

@pytest.mark.asyncio
async def test_take_subjective_questions_assessment_unauthorized(client):
    """Test that the assessment endpoint returns 403 without token."""
    response = await client.post("/api/v1/assessments")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_take_subjective_questions_assessment_invalid_token(client, mock_google_verify):
    """Test that the assessment endpoint returns 401 with invalid token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post("/api/v1/assessments", headers={"Authorization": "Bearer invalid_token"})
    assert response.status_code == 401