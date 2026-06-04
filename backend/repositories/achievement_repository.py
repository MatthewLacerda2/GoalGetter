from typing import Optional
from sqlalchemy import select
from backend.models.achievement import Achievement
from backend.repositories.base import BaseRepository

class AchievementRepository(BaseRepository[Achievement]):
    
    async def create(self, entity: Achievement) -> Achievement:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[Achievement]:
        stmt = select(Achievement).where(Achievement.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def update(self, entity: Achievement) -> Achievement:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
