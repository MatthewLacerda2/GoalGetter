import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core import clock
from backend.models.base import Base, Embedding

if TYPE_CHECKING:
    from backend.models.goal import Goal
    from backend.models.student_answer import StudentAnswer


class Question(Base):
    """One multiple-choice question of a goal's bank (#131).

    A question belongs to a **goal**, never to a lesson: the same question can
    be served on any day, and the student may answer it as many times as the
    selection puts it in front of him. Always four options - that is how
    generation works and what the app draws.
    """

    __tablename__ = "questions"
    __table_args__ = (
        CheckConstraint(
            "right_answer_index >= 0 AND right_answer_index <= 3",
            name="check_right_answer_index_range",
        ),
        Index("idx_question_goal_id", "goal_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    goal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("goals.id", ondelete="CASCADE"))
    text: Mapped[str]
    text_embedding: Mapped[Embedding | None]

    option_a: Mapped[str]
    option_b: Mapped[str]
    option_c: Mapped[str]
    option_d: Mapped[str]

    right_answer_index: Mapped[int]
    created_at: Mapped[datetime] = mapped_column(default=clock.now)

    goal: Mapped[Goal] = relationship(back_populates="questions")
    answers: Mapped[list[StudentAnswer]] = relationship(
        back_populates="question", cascade="all, delete-orphan"
    )
