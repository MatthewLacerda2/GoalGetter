from typing import Optional
from sqlalchemy import select, and_
from backend.repositories.base import BaseRepository
from backend.models.multiple_choice_question import MultipleChoiceAnswer

class MultipleChoiceAnswerRepository(BaseRepository[MultipleChoiceAnswer]):
    
    async def create(self, entity: MultipleChoiceAnswer) -> MultipleChoiceAnswer:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[MultipleChoiceAnswer]:
        stmt = select(MultipleChoiceAnswer).where(MultipleChoiceAnswer.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_latest_by_question_and_student(self, question_id: str, student_id: str) -> Optional[MultipleChoiceAnswer]:
        """Get the latest answer for a specific question and student"""
        stmt = select(MultipleChoiceAnswer).where(
            and_(
                MultipleChoiceAnswer.question_id == question_id,
                MultipleChoiceAnswer.student_id == student_id
            )
        ).order_by(MultipleChoiceAnswer.created_at.desc()).limit(1)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def update(self, entity: MultipleChoiceAnswer) -> MultipleChoiceAnswer:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
