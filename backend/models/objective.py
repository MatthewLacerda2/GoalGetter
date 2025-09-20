import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime,  Float, ForeignKey
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship

from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class Objective(Base):
    __tablename__ = "objectives"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    goal_id = Column(String(36), ForeignKey("goals.id"), nullable=False)
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    percentage_completed = Column(Float, nullable=False, default=0)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    last_updated_at = Column(DateTime, nullable=False, default=datetime.now())
    description_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    goal = relationship("Goal", back_populates="objectives")
    student = relationship("Student", back_populates="current_objective", uselist=False)
    student_contexts = relationship("StudentContext", back_populates="objective")
    notes = relationship("ObjectiveNote", back_populates="objective")
    multiple_choice_questions = relationship("MultipleChoiceQuestion", back_populates="objective")
    subjective_questions = relationship("SubjectiveQuestion", back_populates="objective")