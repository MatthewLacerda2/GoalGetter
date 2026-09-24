from enum import Enum
from pydantic import BaseModel, Field

class IntroIcon(str, Enum):
    """Fixed vocabulary of icons Gemini may pick for an introduction screen. Each
    value is a Flutter Material icon name, so the frontend maps it with a single
    const lookup (no hallucinated names possible)."""
    rocket_launch = "rocket_launch"
    flag = "flag"
    lightbulb = "lightbulb"
    menu_book = "menu_book"
    emoji_events = "emoji_events"
    explore = "explore"
    school = "school"
    psychology = "psychology"
    trending_up = "trending_up"
    star = "star"
    track_changes = "track_changes"
    calendar_today = "calendar_today"
    extension = "extension"
    local_fire_department = "local_fire_department"
    map = "map"

class GeminiIntroductionScreen(BaseModel):
    icon: IntroIcon = Field(description="One icon from the fixed set that fits this screen")
    title: str = Field(description="Short, punchy title (a few words)")
    text: str = Field(description="One or two encouraging sentences about the goal")

class GeminiIntroductionScreens(BaseModel):
    screens: list[GeminiIntroductionScreen] = Field(description="3 to 5 introduction screens shown while the goal is being set up")

class GeminiGoalValidation(BaseModel):
    makes_sense: bool = Field(description="Can we infer what the user said or wants?")
    is_harmless: bool = Field(description="The request is not immoral, ill-intended, nor harmful to anyone")
    is_achievable: bool = Field(description="Possible to achieve if the user dedicates to it")
    reasoning: str = Field(description="Succinct: what the user wants, or why it was not validated")

class GeminiStudyPlan(BaseModel):
    goal_name: str = Field(description="Short, clear name for what the user will learn")
    description: str = Field(description="Markdown explanation of the next thing to study and why")

class OnboardingQuestionItem(BaseModel):
    question: str = Field(description="The text of the onboarding question")
    option_a: str = Field(description="Option A")
    option_b: str = Field(description="Option B")
    option_c: str = Field(description="Option C")
    option_d: str = Field(description="Option D")

class GeminiOnboardingQuestionsResponse(BaseModel):
    questions: list[OnboardingQuestionItem] = Field(description="List of onboarding questions to evaluate user baseline knowledge")