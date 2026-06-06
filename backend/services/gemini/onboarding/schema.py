from pydantic import BaseModel, Field

class OnboardingQuestionItem(BaseModel):
    question: str = Field(description="The text of the onboarding question")
    option_a: str = Field(description="Option A")
    option_b: str = Field(description="Option B")
    option_c: str = Field(description="Option C")
    option_d: str = Field(description="Option D")

class GeminiOnboardingQuestionsResponse(BaseModel):
    questions: list[OnboardingQuestionItem] = Field(description="List of onboarding questions to evaluate user baseline knowledge")