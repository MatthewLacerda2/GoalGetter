import uuid

from pgvector.sqlalchemy import Vector
from sqlalchemy import Column, DateTime, ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from backend.core import clock
from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS


class Frontier(Base):
    """Where we are taking the student *now*, for one goal (#133).

    `goals.description` is what he asked for on day one and never changes. It
    stops being the target on about the second week: a student who wanted to
    learn about circuits is taught everything circuits hold and is then taken
    outward - to robotics, say - because a goal names what he wanted to learn
    about, not a course with a finish line.

    **Append-only, like `student_contexts`.** The current frontier is the newest
    row of the goal; the rows before it stay as the record of where he has been
    taken. Nothing here is ever edited or deleted, so "what was this question
    written for?" is answerable months later without a provenance column: it is
    the newest frontier dated before the question.

    A goal always has exactly one current frontier and the first exists from
    creation (`GoalRepository.create`), so no reader ever handles "no frontier
    yet".
    """

    __tablename__ = "frontiers"
    __table_args__ = (Index("idx_frontier_goal_id", "goal_id"),)

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    definition = Column(String, nullable=False)
    definition_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=clock.now)

    goal = relationship("Goal", back_populates="frontiers")
