from sqlalchemy import select
from typing import List, Optional
from backend.repositories.base import BaseRepository
from backend.models.subjective_question import SubjectiveQuestion

class SubjectiveQuestionRepository(BaseRepository[SubjectiveQuestion]):
    
    async def create(self, entity: SubjectiveQuestion) -> SubjectiveQuestion:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[SubjectiveQuestion]:
        stmt = select(SubjectiveQuestion).where(SubjectiveQuestion.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_objective_id(self, objective_id: str) -> List[SubjectiveQuestion]:
        """Get all subjective questions for a specific objective"""
        stmt = select(SubjectiveQuestion).where(SubjectiveQuestion.objective_id == objective_id)
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_unanswered_or_wrong(self, objective_id: str, limit: int) -> List[SubjectiveQuestion]:
        """Get unanswered or wrong subjective questions for a specific objective"""
        unanswered = SubjectiveQuestion.student_answer == None
        wrong = SubjectiveQuestion.llm_approval == False
        stmt = select(SubjectiveQuestion).where(
            SubjectiveQuestion.objective_id == objective_id,
            unanswered | wrong
        ).limit(limit)
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def update(self, entity: SubjectiveQuestion) -> SubjectiveQuestion:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False