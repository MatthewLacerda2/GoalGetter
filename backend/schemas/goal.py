from pydantic import BaseModel, Field, field_validator

class ObjectiveQuestionsRequest(BaseModel):
    """Step 1 of goal creation: the raw thing the user says they want to learn."""
    prompt: str = Field(..., min_length=1, description="What the user wants to learn")

class ObjectiveQuestion(BaseModel):
    """A clarifying multiple-choice question with exactly 4 options (no 'correct' one — these profile the user)."""
    question: str
    options: list[str] = Field(..., description="Exactly 4 options")

    @field_validator("options")
    @classmethod
    def must_have_four_options(cls, v: list[str]) -> list[str]:
        if len(v) != 4:
            raise ValueError("an objective question must have exactly 4 options")
        return v

class ObjectiveAnswer(BaseModel):
    """The user's answer to one objective question (unselected options omitted)."""
    question: str
    answer: str = Field(..., description="The selected option")

class GoalCreationRequest(BaseModel):
    """Shared by step 2 (study-plan preview) and step 3 (create goal): the prompt
    plus the user's answers to the objective questions."""
    prompt: str = Field(..., min_length=1, description="What the user wants to learn")
    answers: list[ObjectiveAnswer] = Field(..., description="Answers to the objective questions")

class StudyPlanResponse(BaseModel):
    """Stateless preview the user reviews before committing to the goal."""
    goal_name: str = Field(..., description="Short, clear name for what the user will learn")
    description: str = Field(..., description="Markdown: the next thing to study and why")

class GoalCommitRequest(BaseModel):
    """Step 3 (POST /goals): commit the goal the user approved in the preview. Carries
    the approved goal_name + description so we persist exactly what they saw (no
    re-generation), plus the prompt/answers the async jobs need for context."""
    prompt: str = Field(..., min_length=1, description="What the user wants to learn")
    answers: list[ObjectiveAnswer] = Field(..., description="Answers to the objective questions")
    goal_name: str = Field(..., min_length=1, description="The approved goal name from the preview")
    description: str = Field(..., min_length=1, description="The approved markdown description from the preview")

class IntroductionScreenData(BaseModel):
    """One welcome/roulette screen shown while the goal is being set up in the background."""
    icon: str = Field(..., description="Material icon name from the fixed set")
    title: str = Field(..., description="Short title")
    text: str = Field(..., description="Short encouraging text")

class GoalCreationResponse(BaseModel):
    """What the client gets after committing a goal: the persisted goal plus the
    introduction screens to show while async setup (resources, lessons) runs."""
    id: str = Field(..., description="The created goal's id")
    name: str = Field(..., description="The goal name")
    introduction_screen_data: list[IntroductionScreenData] = Field(..., description="Screens to display while setup runs")
