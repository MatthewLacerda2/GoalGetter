from sqlalchemy import select, and_, desc
from typing import List, Optional, Tuple
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
    
    async def get_latest_with_accuracy(self, student_id: str, limit: int = 10) -> Tuple[List[SubjectiveAnswer], float]:
        """
        Get latest N subjective answers for a student with approval accuracy calculation.
        """
        # Get latest answers ordered by created_at DESC
        stmt = select(SubjectiveAnswer).where(
            SubjectiveAnswer.student_id == student_id
        ).order_by(desc(SubjectiveAnswer.created_at)).limit(limit)
        
        result = await self.db.execute(stmt)
        answers = result.scalars().all()
        
        if not answers:
            return [], 0.0
        
        # Filter out None approvals and calculate accuracy
        valid_answers = [answer for answer in answers if answer.llm_approval is not None]
        
        if not valid_answers:
            return list(answers), 0.0
        
        approved_count = sum(1 for answer in valid_answers if answer.llm_approval is True)
        accuracy = (approved_count / len(valid_answers)) * 100.0 if valid_answers else 0.0
        
        return list(answers), accuracy
    
    async def update(self, entity: SubjectiveAnswer) -> SubjectiveAnswer:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
