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

    async def get_unanswered_or_wrong(self, objective_id: str, student_id: str, limit: int) -> List[MultipleChoiceQuestion]:
        # 1. Subquery to rank answers by date so we can find the "latest 3"
        # This uses a Window Function: ROW_NUMBER()
        answer_rank = select(
            MultipleChoiceAnswer,
            func.row_number().over(
                partition_by=MultipleChoiceAnswer.question_id,
                order_by=MultipleChoiceAnswer.created_at.desc()
            ).label('rn')
        ).where(MultipleChoiceAnswer.student_id == student_id).subquery()

        # 2. Main Query joining Question with the ranked answers
        stmt = (
            select(
                MultipleChoiceQuestion,
                func.count(answer_rank.c.id).label('total_attempts'),
                func.count(answer_rank.c.id).filter(
                    answer_rank.c.student_answer_index == MultipleChoiceQuestion.correct_answer_index
                ).label('total_correct'),
                func.count(answer_rank.c.id).filter(
                    and_(
                        answer_rank.c.rn <= 3,
                        answer_rank.c.student_answer_index == MultipleChoiceQuestion.correct_answer_index
                    )
                ).label('latest_3_correct')
            )
            .join(answer_rank, MultipleChoiceQuestion.id == answer_rank.c.question_id, isouter=True)
            .where(MultipleChoiceQuestion.objective_id == objective_id)
            .group_by(MultipleChoiceQuestion.id)
            # Priorities: 
            # 1. Unanswered or Mastery not met (total_correct < 3 or latest_3_correct < 3)
            # 2. Sort by failure percentage
            .order_by(
                # This logic puts "needs work" questions at the top
                case(
                    (func.count(answer_rank.c.id) == 0, 0), # Never answered = highest priority
                    (func.count(answer_rank.c.id).filter(answer_rank.c.student_answer_index == MultipleChoiceQuestion.correct_answer_index) < 3, 1),
                    else_=2
                ),
                # Highest wrong percentage first
                desc(func.cast(func.count(answer_rank.c.id) - func.count(answer_rank.c.id).filter(answer_rank.c.student_answer_index == MultipleChoiceQuestion.correct_answer_index), Float) / 
                    func.nullif(func.count(answer_rank.c.id), 0))
            )
            .limit(limit)
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
