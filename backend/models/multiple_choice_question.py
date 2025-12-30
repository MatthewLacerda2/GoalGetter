import uuid
from enum import Enum
from datetime import datetime
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, ForeignKey, Integer, DateTime
from backend.models.base import Base

class QuestionPurpose(Enum):
    TEACH = "teach"
    EVALUATE = "evaluate"
    THINK = "think"

class MultipleChoiceQuestion(Base):
    """Question table - contains only question data, no student-specific information"""
    __tablename__ = "multiple_choice_questions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    question = Column(String, nullable=False)
    
    option_a = Column(String, nullable=False)
    option_b = Column(String, nullable=False)
    option_c = Column(String, nullable=False)
    option_d = Column(String, nullable=False)
    
    correct_answer_index = Column(Integer, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    ai_model = Column(String, nullable=False)

    objective = relationship("Objective", back_populates="multiple_choice_questions")
    answers = relationship("MultipleChoiceAnswer", back_populates="question", cascade="all, delete-orphan")


class MultipleChoiceAnswer(Base):
    """Answer table - contains student-specific answer data"""
    __tablename__ = "multiple_choice_answers"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    question_id = Column(String(36), ForeignKey("multiple_choice_questions.id"), nullable=False)
    student_id = Column(String(36), ForeignKey("students.id"), nullable=False)
    
    student_answer_index = Column(Integer, nullable=False)
    seconds_spent = Column(Integer, nullable=True, default=None)
    xp = Column(Integer, nullable=True)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    last_updated_at = Column(DateTime, nullable=True, default=None)

    question = relationship("MultipleChoiceQuestion", back_populates="answers")
    student = relationship("Student", back_populates="multiple_choice_answers")