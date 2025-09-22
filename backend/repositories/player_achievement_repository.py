from typing import List, Optional
from sqlalchemy import select, desc
from backend.models.player_achievement import PlayerAchievement
from backend.repositories.base import BaseRepository

class PlayerAchievementRepository(BaseRepository[PlayerAchievement]):
    
    async def create(self, entity: PlayerAchievement) -> PlayerAchievement:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[PlayerAchievement]:
        stmt = select(PlayerAchievement).where(PlayerAchievement.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_student_id(self, student_id: str, limit: Optional[int] = None) -> List[PlayerAchievement]:
        """Get all player achievements for a specific student with optional limit"""
        stmt = select(PlayerAchievement).where(PlayerAchievement.student_id == student_id)
        if limit is not None:
            stmt = stmt.limit(limit)
        stmt = stmt.order_by(desc(PlayerAchievement.achieved_at))
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def update(self, entity: PlayerAchievement) -> PlayerAchievement:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False