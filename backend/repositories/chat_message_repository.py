from datetime import datetime

from sqlalchemy import delete as sql_delete
from sqlalchemy import or_, select

from backend.models.chat_message import ChatMessage
from backend.repositories.base import BaseRepository


class ChatMessageRepository(BaseRepository[ChatMessage]):
    """Tutor-chat exchanges (one row = prompt + the tutor's reply bubbles)."""

    async def create(self, entity: ChatMessage) -> ChatMessage:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def get_by_id(self, entity_id) -> ChatMessage | None:
        stmt = select(ChatMessage).where(ChatMessage.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_goal(
        self, goal_id, limit: int, before: datetime | None = None
    ) -> list[ChatMessage]:
        """This goal's exchanges, newest first; `before` is the pagination cursor
        (strictly older than that `created_at`)."""
        stmt = select(ChatMessage).where(ChatMessage.goal_id == goal_id)
        if before is not None:
            stmt = stmt.where(ChatMessage.created_at < before)
        stmt = stmt.order_by(ChatMessage.created_at.desc(), ChatMessage.id.desc()).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_recent_by_student(self, student_id, limit: int) -> list[ChatMessage]:
        """The student's last exchanges on any goal, newest first. The chain's
        context step reads them the way it reads lesson answers: what the
        person asks about is a reading of the person, not of one subject."""
        stmt = (
            select(ChatMessage)
            .where(ChatMessage.student_id == student_id)
            .order_by(ChatMessage.created_at.desc(), ChatMessage.id.desc())
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def list_missing_embeddings(self, limit: int) -> list[ChatMessage]:
        """Exchanges with either embedding still null, oldest first (#96).

        One query covers both columns: a row whose reply alone is missing is
        fetched once, and the backfill fills only the column that is null.
        Ordered oldest first so the queue drains in the order it formed, and
        capped because the table only grows - a night that hits the cap leaves
        the rest for the next one, which is exactly what "null is the queue"
        buys us.
        """
        stmt = (
            select(ChatMessage)
            .where(
                or_(
                    ChatMessage.prompt_embedding.is_(None),
                    ChatMessage.tutor_response_embedding.is_(None),
                )
            )
            .order_by(ChatMessage.created_at, ChatMessage.id)
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def update(self, entity: ChatMessage) -> ChatMessage:
        await self.db.flush()
        return entity

    async def delete(self, entity_id) -> bool:
        stmt = sql_delete(ChatMessage).where(ChatMessage.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
