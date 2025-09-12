from typing import List
from pydantic import BaseModel

class SubjectiveQuestionsAssessmentResponse(BaseModel):
    assessment_id: str
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
    assessment_id: str

class SubjectiveQuestionsAssessmentEvaluationResponse(BaseModel):
    assessment_id: str
    objective_id: str
    objective_name: str
    objective_percentage_completed: float
    llm_evaluation: str
    llm_metacognition: str
    grade: float