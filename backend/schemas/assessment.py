from typing import List
from pydantic import BaseModel

class SubjectiveQuestionsAssessmentResponse(BaseModel):
    questions: List[str]

class SubjectiveQuestionEvaluationRequest(BaseModel):
    question_id: str
    question: str
    student_answer: str
    
class SubjectiveQuestionEvaluationResponse(BaseModel):
    question_id: str
    question: str
    student_answer: str
    llm_evaluation: str
    llm_metacognition: str
    llm_approval: bool
    
class SubjectiveQuestionsAssessmentEvaluationRequest(BaseModel):
    questions_ids: List[str]

class SubjectiveQuestionsAssessmentEvaluationResponse(BaseModel):
    objective_id: str
    objective_name: str
    objective_percentage_completed: float
    llm_evaluation: str
    llm_metacognition: str
    is_approved: bool
    grade: float

class SubjectiveThinkLessonEvaluationRequest(BaseModel):
    questions_ids: List[str]

class SubjectiveThinkLessonEvaluationResponse(BaseModel):
    llm_evaluation: str
    llm_metacognition: str
    is_progressing: bool
    prowess_scale: int