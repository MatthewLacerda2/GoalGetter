import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core import clock
from backend.models.base import Base, Embedding

if TYPE_CHECKING:
    from backend.models.frontier import Frontier
    from backend.models.onboarding_question import OnboardingQuestion
    from backend.models.question import Question
    from backend.models.resource import Resource
    from backend.models.student import Student

# Where every goal's rating starts: the column default, the rating `rasch.replay`
# starts from, and the fictitious history's first lesson. One number, one home.
START_RATING = 1200


class Goal(Base):
    __tablename__ = "goals"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    student_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    name: Mapped[str | None]
    description: Mapped[str | None]
    description_embedding: Mapped[Embedding | None]
    rating: Mapped[int] = mapped_column(default=START_RATING)
    created_at: Mapped[datetime] = mapped_column(default=clock.now)
    # onupdate: any change to the row (the rating after a lesson, too) moves it, so
    # the goals list can read it as "last studied".
    updated_at: Mapped[datetime] = mapped_column(default=clock.now, onupdate=clock.now)

    student: Mapped[Student] = relationship(back_populates="goals", foreign_keys=[student_id])
    questions: Mapped[list[Question]] = relationship(
        back_populates="goal", cascade="all, delete-orphan"
    )
    frontiers: Mapped[list[Frontier]] = relationship(
        back_populates="goal", cascade="all, delete-orphan"
    )
    onboarding_questions: Mapped[list[OnboardingQuestion]] = relationship(
        back_populates="goal", cascade="all, delete-orphan"
    )
    resources: Mapped[list[Resource]] = relationship(
        back_populates="goal", cascade="all, delete-orphan"
    )
