from re import L
from typing import List
from pydantic import BaseModel, ConfigDict, Field

class MultipleChoiceQuestionResponse(BaseModel):
    id: str
    question: str
    choices: List[str]
    correct_answer_index: int
    
    model_config = ConfigDict(from_attributes=True)
    
class MultipleChoiceActivityResponse(BaseModel):
    questions: List[MultipleChoiceQuestionResponse]

class MultipleChoiceQuestionAnswer(BaseModel):
    id: str
    student_answer_index: int = Field(..., description="something", ge=0, le=4)
    seconds_spent: int = Field(..., description="something", ge=2, le=3600)

class MultipleChoiceActivityEvaluationRequest(BaseModel):
    answers: List[MultipleChoiceQuestionAnswer]
    
class MultipleChoiceActivityEvaluationResponse(BaseModel):
    total_time_spent: int
    student_accuracy: float
    xp: int