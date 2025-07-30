from pydantic import BaseModel, Field
from backend.utils.envs import MIN_NOTES, MAX_NOTES

max_questions: int = 12

class RoadmapInitiationRequest(BaseModel):
    prompt_hint: str = Field(..., ge=8, le=63, description="A hint for the user to properly describe the goal")
    prompt: str = Field(..., ge=16, le=1024, description="The user's declaration of their goal")

class RoadmapInitiationResponse(BaseModel):
    original_prompt: str = Field(..., ge=16, le=1024, description="The user's declaration of their goal")
    questions: list[str] = Field(..., ge=1, le=max_questions, description="The questions to ask the user to understand their goal")

class FollowUpQuestionsAndAnswers(BaseModel):
    question: str = Field(..., ge=5, le=127, description="A question to understand the user's goal")
    answer: str = Field(..., ge=5, le=1024, description="The user's answer to the question")

class RoadmapCreationRequest(BaseModel):
    initiation_response: RoadmapInitiationResponse
    questions_answers: list[FollowUpQuestionsAndAnswers] = Field(..., ge=1, le=max_questions, description="The questions and answers to understand the user's goal")

class Step(BaseModel):
    title: str = Field(..., ge=2, le=100, description="A title for the step")
    description: str = Field(..., ge=0, le=128, description="A description of the step")

class RoadmapCreationResponse(BaseModel):
    steps: list[Step] = Field(..., ge=3, le=16, description="The steps to achieve the goal")
    notes: list[str] = Field(..., ge=MIN_NOTES, le=MAX_NOTES, description="The notes to help the user achieve the goal")
