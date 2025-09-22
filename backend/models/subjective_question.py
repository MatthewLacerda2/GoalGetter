import uuid
from sqlalchemy import Column, String, ForeignKey, Boolean, Integer
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class SubjectiveQuestion(Base):
    __tablename__ = "subjective_questions"
    
    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    objective_id = Column(String(36), ForeignKey("objectives.id"), nullable=False)
    question = Column(String, nullable=False)
    
    student_answer = Column(String, nullable=True, default=None)
    llm_evaluation = Column(String, nullable=True, default=None)
    llm_metacognition = Column(String, nullable=True, default=None)
    llm_evaluation_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    llm_metacognition_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    llm_approval = Column(Boolean, nullable=True, default=None)
    xp = Column(Integer, nullable=True)
    
    objective = relationship("Objective", back_populates="subjective_questions")