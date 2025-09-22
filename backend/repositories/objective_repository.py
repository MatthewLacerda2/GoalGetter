from typing import List, Optional
from sqlalchemy import select, desc
from sqlalchemy.orm import selectinload
from backend.models.objective import Objective
from backend.repositories.base import BaseRepository

class ObjectiveRepository(BaseRepository[Objective]):
    
    async def create(self, entity: Objective) -> Objective:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[Objective]:
        stmt = select(Objective).where(Objective.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_goal_id(self, goal_id: str) -> List[Objective]:
        stmt = select(Objective).where(Objective.goal_id == goal_id).order_by(desc(Objective.created_at))
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_latest_by_goal_id(self, goal_id: str) -> Optional[Objective]:
        stmt = select(Objective).where(Objective.goal_id == goal_id).order_by(desc(Objective.created_at)).limit(1)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_recent_by_goal_id(self, goal_id: str, limit: int) -> List[Objective]:
        stmt = select(Objective).where(Objective.goal_id == goal_id).order_by(desc(Objective.created_at)).limit(limit)
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_latest_by_goal_id_with_notes(self, goal_id: str) -> Optional[Objective]:
        stmt = select(Objective).options(
            selectinload(Objective.notes)
        ).where(Objective.goal_id == goal_id).order_by(desc(Objective.created_at)).limit(1)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def update(self, entity: Objective) -> Objective:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False