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
    student_answer_index: int = Field(..., description="The zero-based index of the student's answer", ge=0, le=4)
    seconds_spent: int = Field(..., description="Amount of seconds spent in the question", ge=2, le=3600)

class MultipleChoiceActivityEvaluationRequest(BaseModel):
    answers: List[MultipleChoiceQuestionAnswer]# = Field(..., min_length=6)
    
class MultipleChoiceActivityEvaluationResponse(BaseModel):
    total_seconds_spent: int = Field(..., description="Total amount of seconds spent in all questions in the lesson", ge=8, le=3600)
    student_accuracy: float = Field(..., description="Percentage of right answers over amount of questions", ge=0, le=100)
    xp: int = Field(..., description="Total amount of XP gained by all the questions in the lesson", ge=4)