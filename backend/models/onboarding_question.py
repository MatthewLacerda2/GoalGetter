import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import CheckConstraint, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core import clock
from backend.models.base import Base

if TYPE_CHECKING:
    from backend.models.goal import Goal


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

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    goal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("goals.id", ondelete="CASCADE"))
    question: Mapped[str]

    option_a: Mapped[str]
    option_b: Mapped[str]
    option_c: Mapped[str]
    option_d: Mapped[str]

    # Who wrote the question: the Gemini model that generated it, or the
    # literal "system" for the four standard questions and for the row holding
    # the student's own words (#132). NOT NULL - the column is in the initial
    # migration, so there is no row from before it existed, and a row that
    # cannot say where it came from is the one thing this column is for.
    ai_model: Mapped[str]

    selected_option_index: Mapped[int | None]
    # How long he spent on the question, in whole seconds, as the app measured
    # it (#174) - named after `student_answers.total_seconds`, one word for one
    # thing. Nullable: an older client or a clock that could not be read sends
    # none, and losing the duration must never lose the answer. NULL too on the
    # row holding the student's own words, which the app does not time. Stored
    # for deciding how many onboarding questions to ask; nothing reads it yet.
    total_seconds: Mapped[int | None]
    created_at: Mapped[datetime] = mapped_column(default=clock.now)

    goal: Mapped[Goal] = relationship(back_populates="onboarding_questions")
