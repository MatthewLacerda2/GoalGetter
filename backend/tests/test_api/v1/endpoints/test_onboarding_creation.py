import pytest
from backend.schemas.student import TokenResponse
from backend.schemas.goal import GoalFullCreationRequest

full_creation_request = GoalFullCreationRequest(
    goal_name="Create a Python Application",
    goal_description="Create a Python App for Data Science",
    first_objective_name="Create a Bare Minimum Python Script",
    first_objective_description="Learn Programming Fundamentals to create a bare minimum Python script"
)

@pytest.mark.asyncio
async def test_generate_full_creation_success(client, mock_google_verify, test_db, student_factory):
    """Test that the onboarding generate full creation endpoint returns a valid response for a valid request."""
    # Create user with google_id="12345" using student_factory
    await student_factory(email="test1@example.com", google_id="12345", name="Test User 1")
    await test_db.commit()
        
    response = await client.post(
        "/api/v1/onboarding/full_creation",
        headers={"Authorization": "Bearer valid_google_token"},
        json=full_creation_request.model_dump()
    )
    assert response.status_code == 201
    validated_response = TokenResponse.model_validate(response.json())
    assert validated_response.student.email == "test1@example.com"

@pytest.mark.asyncio
async def test_generate_full_creation_existing_user(client, mock_google_verify, test_db, student_factory):
    """Test full creation with existing user - should allow adding new goals"""
    await student_factory(email="test1@example.com", google_id="12345", name="Test User 1")
    await test_db.commit()
    
    first_response = await client.post(
        "/api/v1/onboarding/full_creation",
        headers={"Authorization": "Bearer valid_google_token"},
        json=full_creation_request.model_dump()
    )
    assert first_response.status_code == 201
    
    second_request = GoalFullCreationRequest(
        goal_name="Second Goal",
        goal_description="Second Goal Description",
        first_objective_name="Second Objective",
        first_objective_description="Second Objective Description"
    )
    second_response = await client.post(
        "/api/v1/onboarding/full_creation",
        headers={"Authorization": "Bearer valid_google_token"},
        json=second_request.model_dump()
    )
    assert second_response.status_code == 201

@pytest.mark.asyncio
async def test_generate_full_creation_invalid_token(client, mock_google_verify):
    """Test full creation with invalid Google token"""
    mock_google_verify.side_effect = Exception("Invalid token")
    response = await client.post(
        "/api/v1/onboarding/full_creation",
        headers={"Authorization": "Bearer invalid_token"},
        json=full_creation_request.model_dump()
    )
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_generate_full_creation_missing_token(client):
    """Test full creation without providing token"""
    response = await client.post(
        "/api/v1/onboarding/full_creation",
        json=full_creation_request.model_dump()
    )
    assert response.status_code == 403
