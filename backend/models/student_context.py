import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core import clock
from backend.models.base import Base, Embedding

if TYPE_CHECKING:
    from backend.models.student import Student


class StudentContext(Base):
    """The app's reading of a learner: what they know (`state`) and how they
    think (`metacognition`).

    It belongs to the **student**, not to a goal (#87). What the app knows about
    a person does not change when they switch from law to history, and writing
    one context per goal would pay Gemini once per goal to say much the same thing.
    What is goal-specific reaches a prompt as the goal's own name and
    description.

    A stale context is retired with `is_still_valid = False`, never deleted: it
    is progression history the student is meant to be able to read.
    """

    __tablename__ = "student_contexts"
    __table_args__ = (Index("idx_student_context_student", "student_id"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    student_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    state: Mapped[str]
    state_embedding: Mapped[Embedding | None]
    metacognition: Mapped[str]
    metacognition_embedding: Mapped[Embedding | None]
    is_still_valid: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(default=clock.now)

    student: Mapped[Student] = relationship(back_populates="student_contexts")
