from typing import List
from pydantic import BaseModel, Field

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
    llm_evaluation: str = Field(..., description="The AI's assessment of the student's answer")
    llm_metacognition: str = Field(..., description="The AI's assessment of the student's understanding")
    llm_approval: bool = Field(..., description="Was the student's prowess satisfactory?")
    
class SubjectiveQuestionsAssessmentEvaluationRequest(BaseModel):
    questions_ids: List[str] = Field(..., description="The IDs of the questions the student answered")

class SubjectiveQuestionsAssessmentEvaluationResponse(BaseModel):
    llm_evaluation: str = Field(..., description="The AI's assessment of the student's answer")
    llm_metacognition: str = Field(..., description="The AI's assessment of the student's understanding")
    is_approved: bool = Field(..., description="Was the student's prowess satisfactory?")
    grade: float = Field(..., description="Estimation of the student's prowess", ge=0, le=10)

class SubjectiveThinkLessonEvaluationRequest(BaseModel):
    questions_ids: List[str]

class SubjectiveThinkLessonEvaluationResponse(BaseModel):
    llm_evaluation: str = Field(..., description="The AI's assessment of the student's answer")
    llm_metacognition: str = Field(..., description="The AI's assessment of the student's understanding")
    is_progressing: bool = Field(..., description="Is the student showing progress?")
    grade: int = Field(..., description="Estimation of the student's prowess", ge=0, le=10)