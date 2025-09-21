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
        """Get all resources for a specific goal"""
        stmt = select(Resource).where(Resource.goal_id == goal_id).order_by(Resource.resource_type, Resource.name)
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_by_objective_id(self, objective_id: str) -> List[Resource]:
        """Get all resources for a specific objective"""
        stmt = select(Resource).where(Resource.objective_id == objective_id).order_by(Resource.resource_type, Resource.name)
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_by_goal_and_objective(self, goal_id: str, objective_id: Optional[str] = None) -> List[Resource]:
        """Get resources for a goal, optionally filtered by objective"""
        conditions = [Resource.goal_id == goal_id]
        if objective_id:
            conditions.append(Resource.objective_id == objective_id)
        
        stmt = select(Resource).where(and_(*conditions)).order_by(Resource.resource_type, Resource.name)
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_by_resource_type(self, resource_type: StudyResourceType) -> List[Resource]:
        """Get all resources of a specific type"""
        stmt = select(Resource).where(Resource.resource_type == resource_type).order_by(Resource.name)
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def search_by_name_or_description(self, search_term: str) -> List[Resource]:
        """Search resources by name or description"""
        search_pattern = f"%{search_term}%"
        stmt = select(Resource).where(
            or_(
                Resource.name.ilike(search_pattern),
                Resource.description.ilike(search_pattern)
            )
        ).order_by(Resource.resource_type, Resource.name)
        result = await self.db.execute(stmt)
        return result.scalars().all()