import uuid
from datetime import datetime
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, ForeignKey, Boolean, Integer, DateTime
from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS

class SubjectiveQuestion(Base):
    """Question table - contains only question data, no student-specific information"""
    __tablename__ = "subjective_questions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    question = Column(String, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    ai_model = Column(String, nullable=False)
    
    objective = relationship("Objective", back_populates="subjective_questions")
    answers = relationship("SubjectiveAnswer", back_populates="question", cascade="all, delete-orphan")


class SubjectiveAnswer(Base):
    """Answer table - contains student-specific answer data"""
    __tablename__ = "subjective_answers"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    question_id = Column(String(36), ForeignKey("subjective_questions.id"), nullable=False)
    student_id = Column(String(36), ForeignKey("students.id"), nullable=False)
    
    student_answer = Column(String, nullable=False)
    llm_approval = Column(Boolean, nullable=True, default=None)
    llm_evaluation = Column(String, nullable=True, default=None)
    llm_evaluation_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    llm_metacognition = Column(String, nullable=True, default=None)
    llm_metacognition_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    xp = Column(Integer, nullable=True)
    seconds_spent = Column(Integer, nullable=True, default=None)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    last_updated_at = Column(DateTime, nullable=True, default=None)
    
    question = relationship("SubjectiveQuestion", back_populates="answers")
    student = relationship("Student", back_populates="subjective_answers")