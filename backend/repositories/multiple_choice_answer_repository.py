from typing import Optional, Tuple, List
from sqlalchemy import select, and_, desc
from sqlalchemy.orm import joinedload
from backend.repositories.base import BaseRepository
from backend.models.multiple_choice_question import MultipleChoiceAnswer, MultipleChoiceQuestion

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
    
    async def get_latest_with_accuracy(self, student_id: str, limit: int = 30) -> Tuple[List[MultipleChoiceAnswer], float]:
        """
        Get latest N multiple choice answers for a student with accuracy calculation.
        """
        stmt = select(MultipleChoiceAnswer).options(
            joinedload(MultipleChoiceAnswer.question)
        ).where(
            MultipleChoiceAnswer.student_id == student_id
        ).order_by(desc(MultipleChoiceAnswer.created_at)).limit(limit)
        
        result = await self.db.execute(stmt)
        answers = list(result.unique().scalars().all())
        
        if not answers:
            return [], 0.0
        
        # Calculate accuracy
        correct_count = 0
        for answer in answers:
            # Ensure question is loaded
            if answer.question is None:
                question_stmt = select(MultipleChoiceQuestion).where(
                    MultipleChoiceQuestion.id == answer.question_id
                )
                question_result = await self.db.execute(question_stmt)
                answer.question = question_result.scalar_one_or_none()
            
            if answer.question and answer.student_answer_index == answer.question.correct_answer_index:
                correct_count += 1
        
        accuracy = (correct_count / len(answers)) * 100.0 if answers else 0.0
        
        return answers, accuracy
    
    async def update(self, entity: MultipleChoiceAnswer) -> MultipleChoiceAnswer:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
