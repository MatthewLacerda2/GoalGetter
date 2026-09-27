import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core import clock
from backend.models.base import Base

if TYPE_CHECKING:
    from backend.models.question import Question


class StudentAnswer(Base):
    """One answer to one question, at one moment (#131).

    **Answering the same question five times leaves five rows.** That history is
    the point: "wrong on Monday, right on Tuesday, wrong again on Friday" is
    what says whether the student actually learned, and it is only readable
    because nothing here is ever overwritten.

    `is_correct` is deliberately not a column: it **is**
    `selected_index == question.right_answer_index`, and a stored copy is a
    second truth that can disagree with the first. The join is cheap.

    `lesson_id` is a **mark, not a foreign key**. There is no `lessons` table
    and there will not be one: a lesson is the cut of questions this student was
    shown at this moment, not a row that owns anything. The backend mints the
    mark when it saves the batch - the client never sends one - so it says only
    "these answers arrived together". Nothing else in the schema points at it.

    `position` is where the answer sat inside its lesson, 0-based. Stored on
    purpose (the user, 2026-09-24): insertion order is an accident of the
    payload, and the order the student was asked in is a fact worth recording.
    A lesson's answers, and the rating walk over the whole history, are read
    back in that order (`repositories/student_answer_repository.py`).
    """

    __tablename__ = "student_answers"
    __table_args__ = (
        CheckConstraint(
            "selected_index >= 0 AND selected_index <= 3",
            name="check_selected_index_range",
        ),
        Index("idx_student_answer_question_id_created_at", "question_id", "created_at"),
        Index("idx_student_answer_lesson_id", "lesson_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    question_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("questions.id", ondelete="CASCADE"))
    lesson_id: Mapped[uuid.UUID]
    position: Mapped[int]

    selected_index: Mapped[int]
    total_seconds: Mapped[int | None]
    created_at: Mapped[datetime] = mapped_column(default=clock.now)

    question: Mapped[Question] = relationship(back_populates="answers")
