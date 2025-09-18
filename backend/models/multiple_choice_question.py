from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, ForeignKey, Integer, JSON, DateTime
from datetime import datetime
import uuid
from backend.models.base import Base

class MultipleChoiceQuestion(Base):
    __tablename__ = "multiple_choice_questions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    question = Column(String, nullable=False)
    
    choices = Column(JSON, nullable=False)
    correct_answer_index = Column(Integer, nullable=False)
    student_answer_index = Column(Integer, nullable=True, default=None)
    seconds_spent = Column(Integer, nullable=True, default=None)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    last_updated_at = Column(DateTime, nullable=True, default=None)

    objective = relationship("Objective", back_populates="multiple_choice_questions")