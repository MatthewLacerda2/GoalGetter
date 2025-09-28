from typing import List
from sqlalchemy import select
from backend.repositories.base import BaseRepository
from backend.models.multiple_choice_question import MultipleChoiceQuestion

class MultipleChoiceQuestionRepository(BaseRepository[MultipleChoiceQuestion]):
    
    async def create(self, entity: MultipleChoiceQuestion) -> MultipleChoiceQuestion:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> MultipleChoiceQuestion | None:
        stmt = select(MultipleChoiceQuestion).where(MultipleChoiceQuestion.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_unanswered_or_wrong(self, objective_id: str, limit: int) -> List[MultipleChoiceQuestion]:
        """Get unanswered or wrong questions for a specific objective"""
        unanswered = MultipleChoiceQuestion.student_answer_index == None
        wrong = MultipleChoiceQuestion.student_answer_index != MultipleChoiceQuestion.correct_answer_index
        stmt = select(MultipleChoiceQuestion).where(
            MultipleChoiceQuestion.objective_id == objective_id,
            unanswered | wrong
        ).limit(limit)
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
