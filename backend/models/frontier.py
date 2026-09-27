import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core import clock
from backend.models.base import Base, Embedding

if TYPE_CHECKING:
    from backend.models.goal import Goal


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

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    goal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("goals.id", ondelete="CASCADE"))
    definition: Mapped[str]
    definition_embedding: Mapped[Embedding | None]
    created_at: Mapped[datetime] = mapped_column(default=clock.now)

    goal: Mapped[Goal] = relationship(back_populates="frontiers")
