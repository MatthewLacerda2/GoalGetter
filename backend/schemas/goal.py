from datetime import datetime

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
    description: str = Field(
        ..., min_length=1, description="The approved markdown description from the preview"
    )


class StandardQuestionData(BaseModel):
    """One standard onboarding question, as keys (#132).

    Keys, never sentences: what the student reads is the ARB entry the frontend
    looks the key up in, in each of the five locales, while the English the
    database stores lives in `services/onboarding/standard_questions.py` where
    a prompt can read it.
    """

    key: str = Field(..., description="The question's key, an ARB entry on the client")
    options: list[str] = Field(..., description="The four option keys, in the order asked")


class GoalCreationResponse(BaseModel):
    """What the client gets after committing a goal: the persisted goal plus the
    standard questions to ask while the chain generates its first batch (#132)."""

    id: str = Field(..., description="The created goal's id")
    name: str = Field(..., description="The goal name")
    standard_questions: list[StandardQuestionData] = Field(
        ..., description="Questions to ask while the first batch generates"
    )


class StandardAnswer(BaseModel):
    """One answer to a standard question, both sides of it a key."""

    question_key: str = Field(..., min_length=1, description="The question's key")
    option_key: str = Field(..., min_length=1, description="The key of the option picked")


class StandardAnswersRequest(BaseModel):
    """What the student answered before his first lesson. Partial by design: he
    may skip out at any question, and what he did answer is still worth keeping."""

    answers: list[StandardAnswer] = Field(..., description="The answers given, in any order")


class GoalResponse(BaseModel):
    """One goal in GET /goals. Carries every field the goals list and the goal detail
    screen show, so the detail screen needs no fetch of its own."""

    id: str
    name: str
    description: str
    current_elo: int = Field(..., description="The student's rating for this goal (goals.rating)")
    is_active: bool = Field(
        ..., description="Whether this is the student's active goal (students.current_goal_id)"
    )
    created_at: datetime
    updated_at: datetime = Field(
        ..., description="Bumped whenever the goal row changes, e.g. the rating after a lesson"
    )


class SetActiveGoalResponse(BaseModel):
    """PUT /goals/{goal_id}/set-active: the goal that is now active."""

    goal_id: str
