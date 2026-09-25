import uuid

from pgvector.sqlalchemy import Vector
from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from backend.core import clock
from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS


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

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    text = Column(String, nullable=False)
    text_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)

    option_a = Column(String, nullable=False)
    option_b = Column(String, nullable=False)
    option_c = Column(String, nullable=False)
    option_d = Column(String, nullable=False)

    right_answer_index = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=clock.now)

    goal = relationship("Goal", back_populates="questions")
    answers = relationship("StudentAnswer", back_populates="question", cascade="all, delete-orphan")
