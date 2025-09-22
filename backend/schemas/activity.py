from typing import List
from pydantic import BaseModel, ConfigDict

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
    student_answer_index: int
    seconds_spent: int

class MultipleChoiceActivityEvaluationRequest(BaseModel):
    answers: List[MultipleChoiceQuestionAnswer]
    total_time_spent: int
    student_accuracy: float
    combo: int
    
class MultipleChoiceActivityEvaluationResponse(BaseModel):
    total_time_spent: int
    student_accuracy: float
    combo: int