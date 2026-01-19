from pydantic import BaseModel

class OllamaSubjectiveEvaluationReview(BaseModel):
    evaluation: str
    information: str
    metacognition: str
    approval: bool

class OllamaSubjectiveEvaluationReviewResponse(BaseModel):
    evaluation: str
    information: str
    metacognition: str
    approval: bool
    ai_model: str