import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Index, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class Goal(Base):
    __tablename__ = "goals"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    name = Column(String, nullable=True)
    description = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    student = relationship("Student", back_populates="goals", foreign_keys=[student_id])
    resources = relationship("Resource", back_populates="goal")
    objectives = relationship("Objective", back_populates="goal")
    student_contexts = relationship("StudentContext", back_populates="goal")
    player_achievements = relationship("PlayerAchievement", back_populates="goal")