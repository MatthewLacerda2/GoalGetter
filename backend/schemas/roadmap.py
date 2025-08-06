from pydantic import BaseModel, Field

class RoadmapInitiationRequest(BaseModel):
    prompt_hint: str = Field(..., description="A hint for the user to properly describe the goal")
    prompt: str = Field(..., description="The user's declaration of their goal")

class RoadmapInitiationResponse(BaseModel):
    original_prompt: str = Field(..., description="The user's declaration of their goal")
    questions: list[str] = Field(..., description="The questions to ask the user to understand their goal")

class FollowUpQuestionsAndAnswers(BaseModel):
    question: str = Field(..., description="A question to understand the user's goal")
    answer: str = Field(..., description="The user's answer to the question")

class RoadmapCreationRequest(BaseModel):
    prompt: str = Field(..., description="The user's declaration of their goal")
    questions_answers: list[FollowUpQuestionsAndAnswers] = Field(..., description="The questions and answers to understand the user's goal")

class Step(BaseModel):
    title: str = Field(..., description="A title for the step")
    description: str = Field(..., description="A description of the step")

class RoadmapCreationResponse(BaseModel):
    steps: list[Step] = Field(..., description="The steps to achieve the goal")
    notes: list[str] = Field(..., description="The notes to help the user achieve the goal")

#TODO: gemini is not obeying the character limit strictly