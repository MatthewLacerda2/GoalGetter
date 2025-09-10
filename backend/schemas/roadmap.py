from pydantic import BaseModel, Field

#TODO: gemini is not obeying the character limit strictly
class GoalCreationFollowUpQuestionsRequest(BaseModel):
    prompt_hint: str = Field(..., description="A hint for the user to properly describe the goal")
    prompt: str = Field(..., description="The user's declaration of their goal")

class GoalCreationFollowUpQuestionsResponse(BaseModel):
    original_prompt: str = Field(..., description="The user's declaration of their goal")
    questions: list[str] = Field(..., description="The questions to ask the user to understand their goal")