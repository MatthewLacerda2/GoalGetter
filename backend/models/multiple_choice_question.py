from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, ForeignKey, Integer, JSON
import uuid
from backend.models.base import Base

class MultipleChoiceQuestion(Base):
    __tablename__ = "multiple_choice_questions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    student_context_id = Column(String(36), ForeignKey("student_contexts.id"), nullable=False)
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    activity_id = Column(String(36), nullable=False)
    question = Column(String, nullable=False)
    choices = Column(JSON, nullable=False)
    correct_answer_index = Column(Integer, nullable=False)
    student_answer_index = Column(Integer, nullable=True, default=None)
    seconds_spent = Column(Integer, nullable=True, default=None)

    student_context = relationship("StudentContext", back_populates="multiple_choice_questions")
    objective = relationship("Objective", back_populates="multiple_choice_questions")