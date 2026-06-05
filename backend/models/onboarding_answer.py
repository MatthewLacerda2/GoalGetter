import uuid
from datetime import datetime
from sqlalchemy import Column, ForeignKey, Integer, DateTime, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from backend.models.base import Base

class OnboardingAnswer(Base):
    __tablename__ = "onboarding_answers"
    __table_args__ = (
        CheckConstraint('selected_option_index >= 0 AND selected_option_index <= 3', name='check_selected_option_index_range'),
        Index('idx_onboarding_answer_question_id', 'question_id'),
        Index('idx_onboarding_answer_student_id', 'student_id'),
    )
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    question_id = Column(UUID(as_uuid=True), ForeignKey("onboarding_questions.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    
    selected_option_index = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)

    question = relationship("OnboardingQuestion", back_populates="answers")
    student = relationship("Student", back_populates="onboarding_answers")
