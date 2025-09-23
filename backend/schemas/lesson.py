from typing import List
from pydantic import BaseModel, ConfigDict

class MultipleChoiceQuestionResponse(BaseModel):
    id: str
    question: str
    choices: List[str]
    correct_answer_index: int
    
    model_config = ConfigDict(from_attributes=True)

class SubjectiveQuestionResponse(BaseModel):
    id: str
    question: str
    
    model_config = ConfigDict(from_attributes=True)

class LessonStartResponse(BaseModel):
    multiple_choice_questions: List[MultipleChoiceQuestionResponse]
    subjective_questions: List[SubjectiveQuestionResponse]

class SubjectiveQuestionEvaluationRequest(BaseModel):
    question_id: str
    question: str
    student_answer: str

class SubjectiveQuestionEvaluationResponse(BaseModel):
    question_id: str
    question: str
    student_answer: str
    llm_approval: bool
    llm_evaluation: str
    llm_metacognition: str

class LessonFinishRequest(BaseModel):
    mc_ids: List[str]
    subjectives_ids: List[str]

class LessonFinishResponse(BaseModel):
    total_time_spent: int
    student_accuracy: float
    xp: int