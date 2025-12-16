from typing import List
from pydantic import BaseModel

class OllamaMultipleChoiceQuestion(BaseModel):
    question: str
    choices: List[str]
    correct_answer_index: int

class OllamaMultipleChoiceQuestionsList(BaseModel):
    questions: List[OllamaMultipleChoiceQuestion]
