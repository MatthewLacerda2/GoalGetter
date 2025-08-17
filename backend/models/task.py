import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime,  Float
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship

from backend.models.base import Base
#TODO: figure this out
class Objective(Base):
    __tablename__ = "objectives"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_id = Column(String(36), nullable=False)
    goal_id = Column(String(36), nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    name = Column(String, nullable=False)
    description = Column(String, nullable=False)
    description_embedding = Column(Vector(3072), nullable=True)
    percentage_completed = Column(Float, nullable=False, default=0)
    
    student = relationship("Student", back_populates="objectives")
    goal = relationship("Goal", back_populates="objectives")