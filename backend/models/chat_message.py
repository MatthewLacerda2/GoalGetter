import uuid
from datetime import datetime
from pgvector.sqlalchemy import Vector
from sqlalchemy.orm import relationship
from sqlalchemy import Boolean, Column, String, DateTime, ForeignKey, Index
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from backend.utils.envs import NUM_DIMENSIONS
from backend.models.base import Base

class ChatMessage(Base):
    """One tutor-chat **exchange** per row: the student's prompt and the tutor's
    reply, which is Gemini's `messages` array (one chat bubble per string).

    Scoped to a goal: the chat is per goal, and it goes with the goal
    (`ondelete="CASCADE"`, DB-level only — no ORM relationship on `Goal`).
    `is_liked` likes the whole reply (the heart sits on its last bubble)."""
    __tablename__ = "chat_messages"
    __table_args__ = (
        Index('idx_chat_message_goal_created', 'goal_id', 'created_at'),
    )

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    goal_id = Column(UUID(as_uuid=True), ForeignKey("goals.id", ondelete="CASCADE"), nullable=False)
    prompt = Column(String, nullable=False)
    prompt_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    tutor_responses = Column(ARRAY(String), nullable=False)
    tutor_response_embedding = Column(Vector(NUM_DIMENSIONS), nullable=True)
    is_liked = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=datetime.now)

    student = relationship("Student", back_populates="chat_messages")
