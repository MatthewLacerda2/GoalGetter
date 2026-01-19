from typing import List, Optional
from sqlalchemy import select
from backend.repositories.base import BaseRepository
from backend.models.multiple_choice_question import MultipleChoiceQuestion

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
    
    async def get_unanswered_or_wrong(self, objective_id: str, student_id: str, limit: int) -> List[MultipleChoiceQuestion]:
        """Get unanswered or wrong questions for a specific objective and student"""
        from backend.repositories.multiple_choice_answer_repository import MultipleChoiceAnswerRepository
        
        # Get all questions for the objective
        all_questions_stmt = select(MultipleChoiceQuestion).where(
            MultipleChoiceQuestion.objective_id == objective_id
        )
        all_questions_result = await self.db.execute(all_questions_stmt)
        all_questions = all_questions_result.scalars().all()
        
        answer_repo = MultipleChoiceAnswerRepository(self.db)
        
        # Filter questions: unanswered or wrong (based on latest answer)
        filtered_questions = []
        for question in all_questions:
            latest_answer = await answer_repo.get_latest_by_question_and_student(question.id, student_id)
            
            if latest_answer is None:
                # Unanswered
                filtered_questions.append(question)
            elif latest_answer.student_answer_index != question.correct_answer_index:
                # Wrong (based on latest answer)
                filtered_questions.append(question)
            
            if len(filtered_questions) >= limit:
                break
        
        return filtered_questions[:limit]
    
    async def update(self, entity: MultipleChoiceQuestion) -> MultipleChoiceQuestion:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
