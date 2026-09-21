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
    """POST /goals/{goal_id}/lessons: the opened lesson and its questions, in order."""
    lesson_id: str
    questions: list[LessonQuestionResponse]


class LessonAnswerItem(BaseModel):
    """The student's first attempt at one question."""
    question_id: UUID
    choice_index: int = Field(..., ge=0, le=3)
    seconds_spent: int = Field(..., ge=0)


class LessonAnswersRequest(BaseModel):
    """POST /goals/{goal_id}/lessons/{lesson_id}/answers: all answers at once."""
    answers: list[LessonAnswerItem] = Field(..., min_length=1)


class LessonEvaluation(BaseModel):
    """The server's grading of a lesson. `elo` is the signed change applied to the goal's rating."""
    total_seconds_spent: int
    student_accuracy: float = Field(..., description="0..100")
    elo: int
