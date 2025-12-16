from pydantic import BaseModel

class OllamaGoalValidation(BaseModel):
    makes_sense: bool
    is_harmless: bool
    is_achievable: bool
    reasoning: str

class OllamaFollowUpValidation(BaseModel):
    has_enough_information: bool
    makes_sense: bool
    is_harmless: bool
    is_achievable: bool
    reasoning: str
