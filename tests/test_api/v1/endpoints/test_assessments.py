import pytest
from backend.utils.envs import NUM_QUESTIONS_PER_EVALUATION
from backend.schemas.assessment import SubjectiveQuestionsAssessmentResponse, SubjectiveQuestionEvaluationRequest, SubjectiveQuestionEvaluationResponse

test_single_question = SubjectiveQuestionEvaluationRequest(
    question_id="a1b2-c3d4",
    question="A Question",
    student_answer="Theres your answer",
    seconds_spent= 10
)

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

@pytest.mark.asyncio
async def test_subjective_question_evaluation_unauthorized(client):
    """Test that the single question evaluation endpoint returns 403 without token."""
    response = await client.post("/api/v1/assessments/evaluate/single_question")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_subjective_question_evaluation_invalid_token(client, mock_google_verify):
    """Test that the single question evaluation endpoint returns 401 with invalid token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post("/api/v1/assessments/evaluate/single_question", headers={"Authorization": "Bearer invalid_token"})
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_subjective_question_evaluation_success(authenticated_client_with_objective, mock_gemini_single_question_review, mock_subjective_question_repository, mock_gemini_embeddings):
    """Test that the single question evaluation endpoint returns a valid response."""
    
    client, access_token = authenticated_client_with_objective
    
    response = await client.post(
        "/api/v1/assessments/evaluate/single_question",
        headers={"Authorization": f"Bearer {access_token}"},
        json=test_single_question.model_dump()
    )
    
    assert response.status_code == 201
    
    assessment_response = SubjectiveQuestionEvaluationResponse.model_validate(response.json())
    assert isinstance(assessment_response, SubjectiveQuestionEvaluationResponse)
    assert assessment_response.question_id == test_single_question.question_id
    assert assessment_response.question == test_single_question.question
    assert assessment_response.llm_evaluation is not None
    assert assessment_response.llm_approval is not None

@pytest.mark.asyncio
async def test_subjective_questions_overall_evaluation_unauthorized(client):
    """Test that the overall evaluation subjective questions endpoint returns 403 without token."""
    response = await client.post("/api/v1/assessments/evaluate/overall")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_subjective_questions_overall_evaluation_invalid_token(client, mock_google_verify):
    """Test that the overall evaluation subjective questions endpoint returns 401 with invalid token."""
    mock_google_verify.side_effect = Exception("Invalid token")
    
    response = await client.post("/api/v1/assessments/evaluate/overall", headers={"Authorization": "Bearer invalid_token"})
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_subjective_questions_overall_evaluation_success(authenticated_client_with_objective, mock_subjective_question_repository, mock_gemini_overall_evaluation_review):
    """Test that the overall evaluation subjective questions endpoint returns a valid response."""
    from backend.schemas.assessment import SubjectiveQuestionsAssessmentEvaluationRequest, SubjectiveQuestionsAssessmentEvaluationResponse
    
    client, access_token = authenticated_client_with_objective
    
    test_questions = SubjectiveQuestionsAssessmentEvaluationRequest(
        questions_ids=[f"id_{i}" for i in range(10)]
    )
    
    response = await client.post(
        "/api/v1/assessments/evaluate/overall",
        headers={"Authorization": f"Bearer {access_token}"},
        json=test_questions.model_dump()
    )
    
    assert response.status_code == 201
    
    assessment_response = SubjectiveQuestionsAssessmentEvaluationResponse.model_validate(response.json())
    assert isinstance(assessment_response, SubjectiveQuestionsAssessmentEvaluationResponse)