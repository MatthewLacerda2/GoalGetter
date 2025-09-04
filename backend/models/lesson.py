from backend.models.base import Base
from sqlalchemy import Column, String, DateTime, ForeignKey, Boolean, JSON, Integer, Float
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

class Lesson(Base):
    __tablename__ = "lessons"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_context_id = Column(String(36), ForeignKey("student_contexts.id"), nullable=False)
    is_evaluation = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    seconds_spent = Column(Integer, nullable=True, default=None)
    student_accuracy = Column(Float, nullable=True, default=None)
    content = Column(JSON, nullable=False)

    student_context = relationship("StudentContext", back_populates="lessons", uselist=False)