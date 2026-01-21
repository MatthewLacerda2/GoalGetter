from typing import List, Optional
from sqlalchemy import select
from backend.models.goal import Goal
from backend.repositories.base import BaseRepository

class GoalRepository(BaseRepository[Goal]):
    
    async def create(self, entity: Goal) -> Goal:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[Goal]:
        stmt = select(Goal).where(Goal.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_student_id(self, student_id: str) -> List[Goal]:
        stmt = select(Goal).where(Goal.student_id == student_id)
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def update(self, entity: Goal) -> Goal:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            await self.db.flush()
            return True
        return False
