from backend.models.base import Base
from sqlalchemy import Column, String, DateTime, ForeignKey, JSON, Integer, Float
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

class Lesson(Base):
    __tablename__ = "lessons"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_context_id = Column(String(36), ForeignKey("student_contexts.id"), nullable=False)
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    content = Column(JSON, nullable=False)
    seconds_spent = Column(Integer, nullable=True, default=None)
    student_accuracy = Column(Float, nullable=True, default=None)
    created_at = Column(DateTime, nullable=False, default=datetime.now())

    student_context = relationship("StudentContext", back_populates="lessons", uselist=False)
    objective = relationship("Objective", back_populates="lessons", uselist=False)