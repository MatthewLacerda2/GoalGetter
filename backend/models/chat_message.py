import uuid
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, Index, String
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core import clock
from backend.models.base import Base, Embedding

if TYPE_CHECKING:
    from backend.models.student import Student


class ChatMessage(Base):
    """One tutor-chat **exchange** per row: the student's prompt and the tutor's
    reply, which is Gemini's `messages` array (one chat bubble per string).

    Scoped to a goal: the chat is per goal, and it goes with the goal
    (`ondelete="CASCADE"`, DB-level only — no ORM relationship on `Goal`).
    `is_liked` likes the whole reply (the heart sits on its last bubble)."""

    __tablename__ = "chat_messages"
    __table_args__ = (Index("idx_chat_message_goal_created", "goal_id", "created_at"),)

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    student_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"))
    goal_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("goals.id", ondelete="CASCADE"))
    prompt: Mapped[str]
    prompt_embedding: Mapped[Embedding | None]
    tutor_responses: Mapped[list[str]] = mapped_column(ARRAY(String))
    tutor_response_embedding: Mapped[Embedding | None]
    is_liked: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(default=clock.now)

    student: Mapped[Student] = relationship(back_populates="chat_messages")
