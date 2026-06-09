from pydantic import BaseModel, Field

class GeminiGoalValidation(BaseModel):
    makes_sense: bool = Field(description="Can we infer what the user said or wants?")
    is_harmless: bool = Field(description="The request is not immoral, ill-intended, nor harmful to anyone")
    is_achievable: bool = Field(description="Possible to achieve if the user dedicates to it")
    reasoning: str = Field(description="Succinct: what the user wants, or why it was not validated")

class OnboardingQuestionItem(BaseModel):
    question: str = Field(description="The text of the onboarding question")
    option_a: str = Field(description="Option A")
    option_b: str = Field(description="Option B")
    option_c: str = Field(description="Option C")
    option_d: str = Field(description="Option D")

class GeminiOnboardingQuestionsResponse(BaseModel):
    questions: list[OnboardingQuestionItem] = Field(description="List of onboarding questions to evaluate user baseline knowledge")