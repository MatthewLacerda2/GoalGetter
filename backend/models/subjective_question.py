import uuid
from datetime import datetime
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, ForeignKey, Boolean, Integer, DateTime
from backend.models.base import Base
from backend.utils.envs import NUM_DIMENSIONS

class SubjectiveQuestion(Base):
    __tablename__ = "subjective_questions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    question = Column(String, nullable=False)
    
    student_answer = Column(String, nullable=True, default=None)
    llm_approval = Column(Boolean, nullable=True, default=None)
    llm_evaluation = Column(String, nullable=True, default=None)
    llm_evaluation_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    llm_metacognition = Column(String, nullable=True, default=None)
    llm_metacognition_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    xp = Column(Integer, nullable=True)
    seconds_spent = Column(Integer, nullable=True, default=None)
    created_at = Column(DateTime, nullable=False, default=datetime.now())
    last_updated_at = Column(DateTime, nullable=True, default=None)
    
    objective = relationship("Objective", back_populates="subjective_questions")