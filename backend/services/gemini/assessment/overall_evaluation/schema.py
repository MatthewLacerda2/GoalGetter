from pydantic import BaseModel

class GeminiSubjectiveEvaluationReview(BaseModel):
    evaluation: str
    information: str
    metacognition: str
    approval: bool