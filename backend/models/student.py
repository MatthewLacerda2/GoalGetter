import uuid
from datetime import datetime
from sqlalchemy import Column, String, DateTime, Integer, CheckConstraint, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from backend.models.base import Base

class Student(Base):
    __tablename__ = "students"
    __table_args__ = (
        CheckConstraint('progress_rating >= 0', name='check_progress_rating_non_negative'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, nullable=False, unique=True)
    google_id = Column(String, nullable=False, unique=True)
    name = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    last_login = Column(DateTime(timezone=True), nullable=False, default=datetime.now)
    progress_rating = Column(Integer, nullable=False, default=1200)
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
        "Goal", back_populates="student", cascade="all, delete-orphan",
        foreign_keys="Goal.student_id",
    )
    chat_messages = relationship("ChatMessage", back_populates="student", cascade="all, delete-orphan")
    student_contexts = relationship("StudentContext", back_populates="student", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="student", cascade="all, delete-orphan")