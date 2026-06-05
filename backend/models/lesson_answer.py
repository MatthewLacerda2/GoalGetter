import uuid
from sqlalchemy import Column, ForeignKey, Integer, Boolean, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from backend.models.base import Base

class LessonAnswer(Base):
    __tablename__ = "lesson_answers"
    __table_args__ = (
        CheckConstraint('selected_option_index >= 0 AND selected_option_index <= 3', name='check_selected_option_index_range'),
        Index('idx_lesson_answer_question_id', 'question_id'),
        Index('idx_lesson_answer_student_id', 'student_id'),
    )
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    question_id = Column(UUID(as_uuid=True), ForeignKey("lesson_questions.id", ondelete="CASCADE"), nullable=False)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    
    selected_option_index = Column(Integer, nullable=False)
    is_correct = Column(Boolean, nullable=False)
    time_spent = Column(Integer, nullable=True)  # Time spent in seconds

    question = relationship("LessonQuestion", back_populates="answers")
    student = relationship("Student", back_populates="lesson_answers")
