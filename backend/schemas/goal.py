from pydantic import BaseModel, Field, field_validator

class ObjectiveQuestionsRequest(BaseModel):
    """Step 1 of goal creation: the raw thing the user says they want to learn."""
    prompt: str = Field(..., min_length=1, description="What the user wants to learn")

class ObjectiveQuestion(BaseModel):
    """A clarifying multiple-choice question with exactly 4 options (no 'correct' one — these profile the user)."""
    question: str
    options: list[str] = Field(..., description="Exactly 4 options")

    @field_validator("options")
    @classmethod
    def must_have_four_options(cls, v: list[str]) -> list[str]:
        if len(v) != 4:
            raise ValueError("an objective question must have exactly 4 options")
        return v
