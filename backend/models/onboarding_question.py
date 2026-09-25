import uuid

from sqlalchemy import CheckConstraint, Column, DateTime, ForeignKey, Index, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from backend.core import clock
from backend.models.base import Base


class OnboardingQuestion(Base):
    """What the student told us while creating a goal, kept until the chain's
    first step turns it into a student context (#88).

    How a row is written - which of the four option columns is filled, when
    `selected_option_index` is NULL, and what `ai_model` holds - is documented
    on `repositories/onboarding_repository.py`, the only thing that reads or
    writes this table.
    """

    __tablename__ = "onboarding_questions"
    __table_args__ = (
        CheckConstraint(
            "selected_option_index >= 0 AND selected_option_index <= 3",
            name="check_selected_option_index_range_onboarding",
        ),
        Index("idx_onboarding_question_goal_id", "goal_id"),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    question = Column(String, nullable=False)

    option_a = Column(String, nullable=False)
    option_b = Column(String, nullable=False)
    option_c = Column(String, nullable=False)
    option_d = Column(String, nullable=False)

    # Who wrote the question: the Gemini model that generated it, or the
    # literal "system" for the four standard questions and for the row holding
    # the student's own words (#132). NOT NULL - the schema is rebuilt on every
    # start, so there is no row from before the column existed, and a row that
    # cannot say where it came from is the one thing this column is for.
    ai_model = Column(String, nullable=False)

    selected_option_index = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=clock.now)

    goal = relationship("Goal", back_populates="onboarding_questions")
