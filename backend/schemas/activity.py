from typing import List
from pydantic import BaseModel

class MultipleChoiceQuestion(BaseModel):
    question: str
    choices: List[str]
    correct_answer: int
    
class MultipleChoiceActivityResponse(BaseModel):
    activity_id: str
    questions: List[MultipleChoiceQuestion]

class MultipleChoiceQuestionAnswer(BaseModel):
    question_id: str
    student_answer_index: int
    seconds_spent: int

class MultipleChoiceActivityEvaluationRequest(BaseModel):
    activity_id: str
    answers: List[MultipleChoiceQuestionAnswer]
    total_time_spent: int
    student_accuracy: float
    combo: int
    
class MultipleChoiceActivityEvaluationResponse(BaseModel):
    activity_id: str
    total_time_spent: int
    student_accuracy: float
    combo: int