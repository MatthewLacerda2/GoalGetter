import uuid
from enum import Enum
from datetime import datetime
from sqlalchemy.orm import relationship
from sqlalchemy import Column, String, ForeignKey, Integer, DateTime, CheckConstraint, Index
from sqlalchemy.dialects.postgresql import UUID
from backend.models.base import Base

class QuestionPurpose(Enum):
    TEACH = "teach"
    EVALUATE = "evaluate"
    THINK = "think"

class MultipleChoiceQuestion(Base):
    """Question table - contains only question data, no student-specific information"""
    __tablename__ = "multiple_choice_questions"
    __table_args__ = (
        CheckConstraint('correct_answer_index >= 0 AND correct_answer_index <= 3', name='check_correct_answer_index_range'),
        Index('idx_mcq_objective_id', 'objective_id'),
    )
    
    id = Column(UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    objective_id = Column(UUID(as_uuid=False), ForeignKey("objectives.id"), nullable=False)
    question = Column(String, nullable=False)
    
    option_a = Column(String, nullable=False)
    option_b = Column(String, nullable=False)
    option_c = Column(String, nullable=False)
    option_d = Column(String, nullable=False)
    
    correct_answer_index = Column(Integer, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    ai_model = Column(String, nullable=False)

    objective = relationship("Objective", back_populates="multiple_choice_questions")
    answers = relationship("MultipleChoiceAnswer", back_populates="question", cascade="all, delete-orphan")
    
    @property
    def choices(self) -> list[str]:
        """Convert option fields to choices list for API responses"""
        return [self.option_a, self.option_b, self.option_c, self.option_d]


class MultipleChoiceAnswer(Base):
    """Answer table - contains student-specific answer data"""
    __tablename__ = "multiple_choice_answers"
    __table_args__ = (
        CheckConstraint('student_answer_index >= 0 AND student_answer_index <= 3', name='check_student_answer_index_range'),
        Index('idx_mca_question_id', 'question_id'),
        Index('idx_mca_student_id', 'student_id'),
    )
    
    id = Column(UUID(as_uuid=False), primary_key=True, default=lambda: str(uuid.uuid4()))
    question_id = Column(UUID(as_uuid=False), ForeignKey("multiple_choice_questions.id"), nullable=False)
    student_id = Column(UUID(as_uuid=False), ForeignKey("students.id"), nullable=False)
    
    student_answer_index = Column(Integer, nullable=False)
    seconds_spent = Column(Integer, nullable=True, default=None)
    xp = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    last_updated_at = Column(DateTime(timezone=True), nullable=True, default=None)

    question = relationship("MultipleChoiceQuestion", back_populates="answers")
    student = relationship("Student", back_populates="multiple_choice_answers")