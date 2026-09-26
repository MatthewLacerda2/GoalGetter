import uuid

from sqlalchemy import Column, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from backend.core import clock
from backend.models.base import Base


class Student(Base):
    """The person. **There is no rating here** (#62): a rating is what the
    student is worth *on one goal*, replayed from the answers he gave under it,
    and a single number across every goal he ever opened would be an average of
    things that are not comparable. `goals.rating` is the only rating there is.
    """

    __tablename__ = "students"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, nullable=False, unique=True)
    google_id = Column(String, nullable=False, unique=True)
    name = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=clock.now)
    last_login = Column(DateTime(timezone=True), nullable=False, default=clock.now)
    # The language he chose in the app (`core/language.py`: a `Language` value).
    # Null until the app first tells us, which is his next request (#172).
    language = Column(String(2), nullable=True)
    # The active goal. Nullable + use_alter because students<->goals reference each
    # other (goals.student_id and students.current_goal_id), a mutual FK Postgres can
    # only build via a deferred ALTER. SET NULL so deleting the active goal is safe.
    current_goal_id = Column(
        UUID(as_uuid=True),
        ForeignKey("goals.id", use_alter=True, ondelete="SET NULL"),
        nullable=True,
    )

    # foreign_keys is required now that two FKs join students<->goals, otherwise
    # SQLAlchemy can't tell which one this relationship rides on.
    goals = relationship(
        "Goal",
        back_populates="student",
        cascade="all, delete-orphan",
        foreign_keys="Goal.student_id",
    )
    chat_messages = relationship(
        "ChatMessage", back_populates="student", cascade="all, delete-orphan"
    )
    student_contexts = relationship(
        "StudentContext", back_populates="student", cascade="all, delete-orphan"
    )
    refresh_tokens = relationship(
        "RefreshToken", back_populates="student", cascade="all, delete-orphan"
    )
