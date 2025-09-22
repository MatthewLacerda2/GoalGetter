from typing import List, Optional
from sqlalchemy import select, desc
from backend.models.objective_note import ObjectiveNote
from backend.repositories.base import BaseRepository

class ObjectiveNoteRepository(BaseRepository[ObjectiveNote]):
    
    async def create(self, entity: ObjectiveNote) -> ObjectiveNote:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[ObjectiveNote]:
        stmt = select(ObjectiveNote).where(ObjectiveNote.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_objective_id(self, objective_id: str) -> List[ObjectiveNote]:
        stmt = select(ObjectiveNote).where(ObjectiveNote.objective_id == objective_id).order_by(desc(ObjectiveNote.created_at))
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def update(self, entity: ObjectiveNote) -> ObjectiveNote:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False