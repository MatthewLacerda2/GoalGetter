from typing import List
from pydantic import BaseModel, Field

class SubjectiveQuestionSchema(BaseModel):
    id: str
    question: str

class SubjectiveQuestionsAssessmentResponse(BaseModel):
    #questions: List[SubjectiveQuestionSchema] #TODO: use this
    questions: List[str]

class SubjectiveQuestionEvaluationRequest(BaseModel):
    question_id: str
    question: str
    student_answer: str
    seconds_spent: int
    
class SubjectiveQuestionEvaluationResponse(BaseModel):
    question_id: str
    question: str
    llm_approval: bool = Field(..., description="Was the student's answer satisfactory?")
    llm_evaluation: str = Field(..., description="The AI's assessment of the student's answer")
    
class SubjectiveQuestionsAssessmentEvaluationRequest(BaseModel):
    questions_ids: List[str] = Field(..., description="The IDs of the questions the student answered")

class SubjectiveQuestionsAssessmentEvaluationResponse(BaseModel):
    llm_evaluation: str = Field(..., description="The AI's assessment of the student's overall performance")
    llm_information: str = Field(..., description="something")
    llm_metacognition: str = Field(..., description="The AI's assessment of the student's understanding")
    is_approved: bool = Field(..., description="Was the student's prowess satisfactory?")