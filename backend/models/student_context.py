import uuid
from sqlalchemy import Column, String, DateTime, Boolean
from datetime import datetime
from backend.models.base import Base
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS

class StudentContext(Base):
    __tablename__ = "student_contexts"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), nullable=False)
    goal_id = Column(String(36), nullable=False)
    context = Column(String, nullable=False)
    context_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    is_still_valid = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    
    student = relationship("Student", back_populates="student_contexts")
    goal = relationship("Goal", back_populates="student_contexts")