import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Float, ForeignKey, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship

from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class Objective(Base):
    __tablename__ = "objectives"
    __table_args__ = (
        CheckConstraint('percentage_completed >= 0 AND percentage_completed <= 100', name='check_percentage_completed_range'),
        Index('idx_objective_goal_id', 'goal_id'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    percentage_completed = Column(Float, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    last_updated_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    ai_model = Column(String, nullable=False)
    
    goal = relationship("Goal", back_populates="objectives")
    student = relationship("Student", back_populates="current_objective", uselist=False)
    student_contexts = relationship("StudentContext", back_populates="objective")
    notes = relationship("ObjectiveNote", back_populates="objective")
    multiple_choice_questions = relationship("MultipleChoiceQuestion", back_populates="objective")
    subjective_questions = relationship("SubjectiveQuestion", back_populates="objective")