import uuid

from pgvector.sqlalchemy import Vector
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from backend.core import clock
from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS


class StudentContext(Base):
    """The app's reading of a learner: what they know (`state`) and how they
    think (`metacognition`).

    It belongs to the **student**, not to a goal (#87). What the app knows about
    a person does not change when they switch from law to history, and writing
    one context per goal paid Gemini once per goal to say much the same thing.
    What is goal-specific reaches a prompt as the goal's own name and
    description.

    A stale context is retired with `is_still_valid = False`, never deleted: it
    is progression history the student is meant to be able to read.
    """

    __tablename__ = "student_contexts"
    __table_args__ = (Index("idx_student_context_student", "student_id"),)

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(
        UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False
    )
    state = Column(String, nullable=False)
    state_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    metacognition = Column(String, nullable=False)
    metacognition_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    is_still_valid = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=clock.now)

    student = relationship("Student", back_populates="student_contexts")
