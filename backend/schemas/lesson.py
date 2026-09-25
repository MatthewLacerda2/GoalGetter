from uuid import UUID

from pydantic import BaseModel, Field


class LessonQuestionResponse(BaseModel):
    """A served multiple-choice question. `correct_answer_index` is included on
    purpose: the app grades inline for feedback; the server re-grades on submit."""

    id: str
    question: str
    choices: list[str] = Field(..., description="Exactly 4 choices")
    correct_answer_index: int = Field(..., ge=0, le=3)


class LessonResponse(BaseModel):
    """POST /goals/{goal_id}/lessons: the questions of this lesson, in order.

    There is no lesson id here, because there is no lesson yet (#131). Serving
    writes nothing: a lesson only becomes a fact when its answers arrive, and
    the backend marks them then.
    """

    questions: list[LessonQuestionResponse]


class LessonAnswerItem(BaseModel):
    """One answer, in the order the student gave it - which is what the stored
    `position` records."""

    question_id: UUID
    choice_index: int = Field(..., ge=0, le=3)
    seconds_spent: int = Field(..., ge=0)


class LessonAnswersRequest(BaseModel):
    """POST /goals/{goal_id}/lessons/answers: all answers at once.

    How many there are is up to the student: nothing recorded what was served,
    so the backend cannot ask for a complete set and does not (the completeness
    rule of #86 went with the `lessons` table). An empty submission is refused
    here, because it would mint a lesson mark over nothing.
    """

    answers: list[LessonAnswerItem] = Field(..., min_length=1)


class LessonEvaluation(BaseModel):
    """The server's grading of a lesson. `elo` is the signed change applied to the goal's rating."""

    total_seconds_spent: int
    student_accuracy: float = Field(..., description="0..100")
    elo: int
