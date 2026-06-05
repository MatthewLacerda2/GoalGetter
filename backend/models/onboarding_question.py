import uuid
from datetime import datetime
from sqlalchemy import Column, String, ForeignKey, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from backend.models.base import Base

class OnboardingQuestion(Base):
    __tablename__ = "onboarding_questions"
    __table_args__ = (
        Index('idx_onboarding_question_goal_id', 'goal_id'),
    )
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    question = Column(String, nullable=False)
    
    option_a = Column(String, nullable=False)
    option_b = Column(String, nullable=False)
    option_c = Column(String, nullable=False)
    option_d = Column(String, nullable=False)
    
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)

    goal = relationship("Goal", back_populates="onboarding_questions")
    answers = relationship("OnboardingAnswer", back_populates="question", cascade="all, delete-orphan")
