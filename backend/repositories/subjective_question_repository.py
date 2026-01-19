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
    
    async def get_unanswered_or_wrong(self, objective_id: str, student_id: str, limit: int) -> List[SubjectiveQuestion]:
        """Get unanswered or wrong subjective questions for a specific objective and student"""
        from backend.repositories.subjective_answer_repository import SubjectiveAnswerRepository
        
        # Get all questions for the objective
        all_questions_stmt = select(SubjectiveQuestion).where(
            SubjectiveQuestion.objective_id == objective_id
        )
        all_questions_result = await self.db.execute(all_questions_stmt)
        all_questions = all_questions_result.scalars().all()
        
        answer_repo = SubjectiveAnswerRepository(self.db)
        
        # Filter questions: unanswered or wrong (based on latest answer)
        filtered_questions = []
        for question in all_questions:
            latest_answer = await answer_repo.get_latest_by_question_and_student(question.id, student_id)
            
            if latest_answer is None:
                # Unanswered
                filtered_questions.append(question)
            elif latest_answer.llm_approval == False:
                # Wrong (based on latest answer)
                filtered_questions.append(question)
            
            if len(filtered_questions) >= limit:
                break
        
        return filtered_questions[:limit]
    
    async def update(self, entity: SubjectiveQuestion) -> SubjectiveQuestion:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False