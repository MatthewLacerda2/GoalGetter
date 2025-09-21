from typing import List, Optional
from sqlalchemy import select, and_, or_, desc, asc
from sqlalchemy.ext.asyncio import AsyncSession
from backend.models.resource import Resource, StudyResourceType
from backend.repositories.base import BaseRepository

class ResourceRepository(BaseRepository[Resource]):
    
    async def create(self, entity: Resource) -> Resource:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[Resource]:
        stmt = select(Resource).where(Resource.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def update(self, entity: Resource) -> Resource:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
    
    async def get_by_goal_id(self, goal_id: str) -> List[Resource]:
        """Get all relevant resources for a specific goal"""
        stmt = select(Resource).where(Resource.goal_id == goal_id).order_by(Resource.resource_type, Resource.name)
        result = await self.db.execute(stmt)
        return result.scalars().all()