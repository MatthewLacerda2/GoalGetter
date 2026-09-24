import uuid
from datetime import datetime

from pgvector.sqlalchemy import Vector
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS


class StudentContext(Base):
    __tablename__ = "student_contexts"
    __table_args__ = (Index("idx_student_context_student_goal", "student_id", "goal_id"),)

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(
        UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False
    )
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    state = Column(String, nullable=False)
    state_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    metacognition = Column(String, nullable=False)
    metacognition_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    is_still_valid = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)

    student = relationship("Student", back_populates="student_contexts")
    goal = relationship("Goal", back_populates="student_contexts")
