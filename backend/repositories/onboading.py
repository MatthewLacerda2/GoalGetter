from typing import Optional
from sqlalchemy import select
from backend.models.onboarding import Onboarding
from backend.repositories.base import BaseRepository

class OnboardingRepository(BaseRepository[Onboarding]):
    
    async def create(self, entity: Onboarding) -> Onboarding:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[Onboarding]:
        stmt = select(Onboarding).where(Onboarding.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def update(self, entity: Onboarding) -> Onboarding:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            self.db.delete(entity)
            await self.db.flush()
            return True
        return False
