from typing import List, Optional
from sqlalchemy.orm import aliased
from sqlalchemy import select, func, case, and_, desc, Float
from backend.repositories.base import BaseRepository
from backend.models.multiple_choice_question import MultipleChoiceQuestion, MultipleChoiceAnswer

class MultipleChoiceQuestionRepository(BaseRepository[MultipleChoiceQuestion]):
    
    async def create(self, entity: MultipleChoiceQuestion) -> MultipleChoiceQuestion:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[MultipleChoiceQuestion]:
        stmt = select(MultipleChoiceQuestion).where(MultipleChoiceQuestion.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_objective_id(self, objective_id: str) -> List[MultipleChoiceQuestion]:
        """Get all questions for a specific objective"""
        stmt = select(MultipleChoiceQuestion).where(
            MultipleChoiceQuestion.objective_id == objective_id
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def update(self, entity: MultipleChoiceQuestion) -> MultipleChoiceQuestion:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
