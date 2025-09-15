import pytest
from backend.schemas.assessment import SubjectiveQuestionsAssessmentResponse

@pytest.mark.asyncio
async def test_get_assessment_success(client, mock_google_verify, test_user_with_objective):
    """Test that the assessment endpoint returns a valid response for a user with a goal."""
    
    mock_google_verify.return_value = {
        'email': test_user_with_objective.email,
        'sub': test_user_with_objective.google_id,
        'name': test_user_with_objective.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    response = await client.post(
        "/api/v1/assessments",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 201
    
    assessment_response = SubjectiveQuestionsAssessmentResponse.model_validate(response.json())
    assert isinstance(assessment_response, SubjectiveQuestionsAssessmentResponse)

@pytest.mark.asyncio
async def test_get_assessment_unauthorized(client):
    """Test that the assessment endpoint returns 403 without token."""
    response = await client.post("/api/v1/assessments")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_assessment_invalid_token(client, mock_google_verify):
    """Test that the assessment endpoint returns 401 with invalid token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post(
        "/api/v1/assessments",
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_get_assessment_no_goal(client, mock_google_verify, test_user):
    """Test that the assessment endpoint returns 400 when student has no goal."""

    mock_google_verify.return_value = {
        'email': test_user.email,
        'sub': test_user.google_id,
        'name': test_user.name
    }
    
    login_response = await client.post(
        "/api/v1/auth/login",
        json={"access_token": "fixture_user_token"}
    )
    access_token = login_response.json()["access_token"]
    
    response = await client.post(
        "/api/v1/assessments",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 400
    assert response.json()["detail"] == "User did not finish the onboarding and does not have an objective."