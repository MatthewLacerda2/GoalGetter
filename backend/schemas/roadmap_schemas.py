from pydantic import BaseModel

class RoadmapInitiationRequest(BaseModel):
    prompt_hint: str
    prompt: str

class RoadmapQuestionsResponse(BaseModel):
    original_prompt: str
    questions: list[str]

class QuestionsAnswers(BaseModel):
    question: str
    answer: str

class RoadmapCreationRequest(BaseModel):
    original_prompt: str
    questions_answers: list[QuestionsAnswers]

class Step(BaseModel):
    title: str
    description: str

class RoadmapCreationResponse(BaseModel):
    steps: list[Step]
    notes: list[str]
