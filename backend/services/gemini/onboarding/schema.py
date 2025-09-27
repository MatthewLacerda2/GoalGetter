from pydantic import BaseModel

class GeminiGoalValidation(BaseModel):
    makes_sense: bool
    is_harmless: bool
    is_achievable: bool
    reasoning: str

class GeminiFollowUpValidation(BaseModel):
    has_enough_information: bool
    makes_sense: bool
    is_harmless: bool
    is_achievable: bool
    reasoning: str