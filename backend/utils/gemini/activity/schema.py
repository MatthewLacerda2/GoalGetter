from typing import List
from pydantic import BaseModel

class GeminiMultipleChoiceQuestion(BaseModel):
    question: str
    choices: List[str]
    correct_answer_index: int

class GeminiMultipleChoiceQuestionsList(BaseModel):
    questions: List[GeminiMultipleChoiceQuestion]