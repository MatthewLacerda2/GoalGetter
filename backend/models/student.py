import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core import clock
from backend.models.base import Base

if TYPE_CHECKING:
    from backend.models.chat_message import ChatMessage
    from backend.models.goal import Goal
    from backend.models.refresh_token import RefreshToken
    from backend.models.student_context import StudentContext


class Student(Base):
    """The person. **There is no rating here** (#62): a rating is what the
    student is worth *on one goal*, replayed from the answers he gave under it,
    and a single number across every goal he ever opened would be an average of
    things that are not comparable. `goals.rating` is the only rating there is.
    """

    __tablename__ = "students"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(unique=True)
    google_id: Mapped[str] = mapped_column(unique=True)
    name: Mapped[str]
    created_at: Mapped[datetime] = mapped_column(default=clock.now)
    last_login: Mapped[datetime] = mapped_column(default=clock.now)
    # The language he chose in the app (`core/language.py`: a `Language` value).
    # Null until the app first tells us, which is his next request (#172).
    language: Mapped[str | None] = mapped_column(String(2))
    # The active goal. Nullable + use_alter because students<->goals reference each
    # other (goals.student_id and students.current_goal_id), a mutual FK Postgres can
    # only build via a deferred ALTER. SET NULL so deleting the active goal is safe.
    current_goal_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("goals.id", use_alter=True, ondelete="SET NULL")
    )

    # foreign_keys is required now that two FKs join students<->goals, otherwise
    # SQLAlchemy can't tell which one this relationship rides on.
    goals: Mapped[list[Goal]] = relationship(
        back_populates="student",
        cascade="all, delete-orphan",
        foreign_keys="Goal.student_id",
    )
    chat_messages: Mapped[list[ChatMessage]] = relationship(
        back_populates="student", cascade="all, delete-orphan"
    )
    student_contexts: Mapped[list[StudentContext]] = relationship(
        back_populates="student", cascade="all, delete-orphan"
    )
    refresh_tokens: Mapped[list[RefreshToken]] = relationship(
        back_populates="student", cascade="all, delete-orphan"
    )
