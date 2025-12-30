import uuid
from datetime import datetime
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, DateTime, Boolean, ForeignKey
from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS

class StudentContext(Base):
    __tablename__ = "student_contexts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), ForeignKey("students.id"), nullable=False)
    goal_id = Column(String(36), ForeignKey("goals.id"), nullable=False)
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    is_still_valid = Column(Boolean, nullable=False, default=True)
    state = Column(String, nullable=False)
    state_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    metacognition = Column(String, nullable=False)
    metacognition_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    ai_model = Column(String, nullable=False)
    
    student = relationship("Student", back_populates="student_contexts")
    goal = relationship("Goal", back_populates="student_contexts")
    objective = relationship("Objective", back_populates="student_contexts")