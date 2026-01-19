from pydantic import BaseModel

class OllamaSingleQuestionReview(BaseModel):
    approval: bool
    evaluation: str
    metacognition: str
