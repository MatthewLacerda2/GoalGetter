from datetime import datetime
from typing import Optional

from sqlalchemy import select, delete as sql_delete

from backend.models.chat_message import ChatMessage
from backend.repositories.base import BaseRepository


class ChatMessageRepository(BaseRepository[ChatMessage]):
    """Tutor-chat exchanges (one row = prompt + the tutor's reply bubbles)."""

    async def create(self, entity: ChatMessage) -> ChatMessage:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def get_by_id(self, entity_id) -> Optional[ChatMessage]:
        stmt = select(ChatMessage).where(ChatMessage.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_goal(
        self, goal_id, limit: int, before: Optional[datetime] = None
    ) -> list[ChatMessage]:
        """This goal's exchanges, newest first; `before` is the pagination cursor
        (strictly older than that `created_at`)."""
        stmt = select(ChatMessage).where(ChatMessage.goal_id == goal_id)
        if before is not None:
            stmt = stmt.where(ChatMessage.created_at < before)
        stmt = stmt.order_by(ChatMessage.created_at.desc(), ChatMessage.id.desc()).limit(limit)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def update(self, entity: ChatMessage) -> ChatMessage:
        await self.db.flush()
        return entity

    async def delete(self, entity_id) -> bool:
        stmt = sql_delete(ChatMessage).where(ChatMessage.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
