import uuid
from datetime import datetime
from sqlalchemy import Column, String, ForeignKey, Integer, DateTime, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from pgvector.sqlalchemy import Vector
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class LessonQuestion(Base):
    __tablename__ = "lesson_questions"
    __table_args__ = (
        CheckConstraint('correct_option_index >= 0 AND correct_option_index <= 3', name='check_correct_option_index_range'),
        Index('idx_lesson_question_goal_id', 'goal_id'),
    )
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    question = Column(String, nullable=False)
    question_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    
    option_a = Column(String, nullable=False)
    option_b = Column(String, nullable=False)
    option_c = Column(String, nullable=False)
    option_d = Column(String, nullable=False)
    
    correct_option_index = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)

    goal = relationship("Goal", back_populates="lesson_questions")
    answers = relationship("LessonAnswer", back_populates="question", cascade="all, delete-orphan")
