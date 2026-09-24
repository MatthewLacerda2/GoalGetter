import uuid

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from backend.core import clock
from backend.models.base import Base


class LessonAnswer(Base):
    """The first attempt at one question in one lesson. The review round after a
    lesson is never submitted, so a lesson holds at most one answer per question.
    `created_at` is what makes "the questions most recently got wrong" a query."""

    __tablename__ = "lesson_answers"
    __table_args__ = (
        CheckConstraint(
            "selected_option_index >= 0 AND selected_option_index <= 3",
            name="check_selected_option_index_range",
        ),
        Index("idx_lesson_answer_question_id", "question_id"),
        UniqueConstraint("lesson_id", "question_id", name="uq_lesson_answer_lesson_question"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    question_id = Column(
        UUID(as_uuid=True), ForeignKey("lesson_questions.id", ondelete="CASCADE"), nullable=False
    )
    lesson_id = Column(
        UUID(as_uuid=True), ForeignKey("lessons.id", ondelete="CASCADE"), nullable=False
    )

    selected_option_index = Column(Integer, nullable=False)
    is_correct = Column(Boolean, nullable=False)
    time_spent = Column(Integer, nullable=True)  # Time spent in seconds
    created_at = Column(DateTime(timezone=True), nullable=False, default=clock.now)

    question = relationship("LessonQuestion", back_populates="answers")
