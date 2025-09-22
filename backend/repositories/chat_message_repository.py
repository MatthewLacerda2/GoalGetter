from typing import List, Optional
from datetime import datetime, timedelta
from sqlalchemy import select, desc
from backend.models.chat_message import ChatMessage
from backend.repositories.base import BaseRepository

class ChatMessageRepository(BaseRepository[ChatMessage]):
    
    async def create(self, entity: ChatMessage) -> ChatMessage:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def create_many(self, entities: List[ChatMessage]) -> List[ChatMessage]:
        self.db.add_all(entities)
        await self.db.flush()
        for entity in entities:
            await self.db.refresh(entity)
        return entities
    
    async def get_by_id(self, entity_id: str) -> Optional[ChatMessage]:
        stmt = select(ChatMessage).where(ChatMessage.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_student_id(
        self, 
        student_id: str, 
        limit: int = 20, 
        from_message_id: Optional[str] = None
    ) -> List[ChatMessage]:
        query = select(ChatMessage).where(ChatMessage.student_id == student_id)
        
        if from_message_id:
            query = query.where(ChatMessage.id >= from_message_id)
        
        query = query.order_by(desc(ChatMessage.created_at)).limit(limit)
        result = await self.db.execute(query)
        return result.scalars().all()
    
    async def get_recent_messages(self, student_id: str, days: int = 1) -> List[ChatMessage]:
        stmt = select(ChatMessage).where(
            ChatMessage.student_id == student_id,
            ChatMessage.created_at > datetime.now() - timedelta(days=days)
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_by_student_and_message_id(self, student_id: str, message_id: str) -> Optional[ChatMessage]:
        stmt = select(ChatMessage).where(
            ChatMessage.id == message_id, 
            ChatMessage.student_id == student_id
        )
        result = await self.db.execute(stmt)
        return result.scalars().first()
    
    async def update(self, entity: ChatMessage) -> ChatMessage:
        # SQLAlchemy will automatically track changes
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
