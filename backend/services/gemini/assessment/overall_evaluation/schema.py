from pydantic import BaseModel

class GeminiSubjectiveEvaluationReview(BaseModel):
    evaluation: str
    information: str
    metacognition: str
    approval: bool

class GeminiSubjectiveEvaluationReviewResponse(BaseModel):
    evaluation: str
    information: str
    metacognition: str
    approval: bool
    ai_model: str