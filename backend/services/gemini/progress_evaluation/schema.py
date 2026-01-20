from typing import List

from pydantic import BaseModel


class GeminiProgressEvaluation(BaseModel):
    state: List[str] = []
    metacognition: List[str] = []
    percentage_completed: float


class GeminiProgressEvaluationResponse(BaseModel):
    state: List[str]
    metacognition: List[str]
    percentage_completed: float
    ai_model: str

