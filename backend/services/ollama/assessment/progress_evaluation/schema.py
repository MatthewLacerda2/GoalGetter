from typing import List
from pydantic import BaseModel

class OllamaProgressEvaluation(BaseModel):
    state: List[str] = []
    metacognition: List[str] = []
    percentage_completed: float

class OllamaProgressEvaluationResponse(BaseModel):
    state: List[str]
    metacognition: List[str]
    percentage_completed: float
    ai_model: str
