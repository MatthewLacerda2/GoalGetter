from pydantic import BaseModel

class GoalValidation(BaseModel):
    makes_sense: bool
    is_harmless: bool
    is_achievable: bool