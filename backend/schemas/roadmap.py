from pydantic import BaseModel, Field
from backend.utils.envs import MIN_NOTES, MAX_NOTES

max_questions: int = 12

class RoadmapInitiationRequest(BaseModel):
    prompt_hint: str = Field(..., min_length=8, max_length=500, description="A hint for the user to properly describe the goal")
    prompt: str = Field(..., min_length=16, max_length=1024, description="The user's declaration of their goal")

class RoadmapInitiationResponse(BaseModel):
    original_prompt: str = Field(..., min_length=16, max_length=1024, description="The user's declaration of their goal")
    questions: list[str] = Field(..., min_length=1, max_length=max_questions, description="The questions to ask the user to understand their goal")

class FollowUpQuestionsAndAnswers(BaseModel):
    question: str = Field(..., min_length=5, max_length=127, description="A question to understand the user's goal")
    answer: str = Field(..., min_length=5, max_length=1024, description="The user's answer to the question")

class RoadmapCreationRequest(BaseModel):
    prompt: str = Field(..., min_length=16, max_length=1024, description="The user's declaration of their goal")
    questions_answers: list[FollowUpQuestionsAndAnswers] = Field(..., min_length=1, max_length=max_questions, description="The questions and answers to understand the user's goal")

class Step(BaseModel):
    title: str = Field(..., min_length=2, max_length=100, description="A title for the step")
    description: str = Field(..., min_length=0, max_length=256, description="A description of the step")

class RoadmapCreationResponse(BaseModel):
    steps: list[Step] = Field(..., min_length=3, max_length=16, description="The steps to achieve the goal")
    notes: list[str] = Field(..., min_length=MIN_NOTES, max_length=MAX_NOTES, description="The notes to help the user achieve the goal")
    
#TODO: gemini is not obeying the character limit strictly
