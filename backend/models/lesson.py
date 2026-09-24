import uuid
from datetime import datetime
from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, Index
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from backend.models.base import Base


class Lesson(Base):
    """One attempt at a lesson: the questions served, then, once answered, its result.

    `question_ids` is the served set, in the order served; the answers endpoint
    refuses any question outside it. The result columns stay NULL until the
    answers arrive, and `finished_at` is what marks a lesson as answered.
    `elo_delta` and `elo_after` feed Home's recent lessons and elo chart.

    There is deliberately no relationship to Goal here (models/goal.py belongs
    to another change); deleting a goal removes its lessons through the
    database-level cascade on `goal_id`.
    """
    __tablename__ = "lessons"
    __table_args__ = (
        Index('idx_lesson_goal_id_created_at', 'goal_id', 'created_at'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    question_ids = Column(ARRAY(UUID(as_uuid=True)), nullable=False)

    finished_at = Column(DateTime(timezone=True), nullable=True)
    total_seconds = Column(Integer, nullable=True)
    accuracy = Column(Float, nullable=True)  # 0..100
    elo_delta = Column(Integer, nullable=True)
    elo_after = Column(Integer, nullable=True)
