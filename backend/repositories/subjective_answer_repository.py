from sqlalchemy import select, and_
from typing import List, Optional
from backend.repositories.base import BaseRepository
from backend.models.subjective_question import SubjectiveAnswer

class SubjectiveAnswerRepository(BaseRepository[SubjectiveAnswer]):
    
    async def create(self, entity: SubjectiveAnswer) -> SubjectiveAnswer:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[SubjectiveAnswer]:
        stmt = select(SubjectiveAnswer).where(SubjectiveAnswer.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_latest_by_question_and_student(self, question_id: str, student_id: str) -> Optional[SubjectiveAnswer]:
        """Get the latest answer for a specific question and student"""
        stmt = select(SubjectiveAnswer).where(
            and_(
                SubjectiveAnswer.question_id == question_id,
                SubjectiveAnswer.student_id == student_id
            )
        ).order_by(SubjectiveAnswer.created_at.desc()).limit(1)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_question_ids(self, question_ids: List[str], student_id: str) -> List[SubjectiveAnswer]:
        """Get all answers for multiple questions for a specific student"""
        stmt = select(SubjectiveAnswer).where(
            and_(
                SubjectiveAnswer.question_id.in_(question_ids),
                SubjectiveAnswer.student_id == student_id
            )
        )
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_latest_by_question_ids(self, question_ids: List[str], student_id: str) -> dict[str, SubjectiveAnswer]:
        """Get latest answers for multiple questions for a specific student, returns dict mapping question_id to answer"""
        # Get all answers for these questions
        all_answers = await self.get_by_question_ids(question_ids, student_id)
        
        # Group by question_id and get the latest for each
        latest_answers = {}
        for answer in all_answers:
            if answer.question_id not in latest_answers:
                latest_answers[answer.question_id] = answer
            elif answer.created_at > latest_answers[answer.question_id].created_at:
                latest_answers[answer.question_id] = answer
        
        return latest_answers
    
    async def update(self, entity: SubjectiveAnswer) -> SubjectiveAnswer:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
