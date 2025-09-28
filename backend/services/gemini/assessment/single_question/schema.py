from pydantic import BaseModel

class GeminiSingleQuestionReview(BaseModel):
    approval: bool
    evaluation: str
    metacognition: str