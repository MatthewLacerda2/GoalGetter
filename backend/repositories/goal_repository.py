from typing import List, Optional
from sqlalchemy import select, func, desc
from backend.models.goal import Goal
from backend.models.objective import Objective
from backend.repositories.base import BaseRepository

class GoalRepository(BaseRepository[Goal]):
    
    async def create(self, entity: Goal) -> Goal:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[Goal]:
        stmt = select(Goal).where(Goal.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_student_id(self, student_id: str) -> List[Goal]:
        stmt = select(Goal).where(Goal.student_id == student_id)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_all(self) -> List[Goal]:
        stmt = select(Goal)
        result = await self.db.execute(stmt)
        return result.scalars().all()

    async def get_goals_with_latest_updates(self, student_id: str):
        stmt = (
            select(
                Goal,
                func.max(Objective.last_updated_at).label('latest_objective_update')
            )
            .join(Objective, Goal.id == Objective.goal_id, isouter=False)
            .where(Goal.student_id == student_id)
            .group_by(Goal.id)
            .order_by(desc(func.max(Objective.last_updated_at)))
        )
        result = await self.db.execute(stmt)
        return result.all()
    
    async def update(self, entity: Goal) -> Goal:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        from sqlalchemy import delete as sql_delete
        stmt = sql_delete(Goal).where(Goal.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0

    async def delete_cascade(self, goal_id: str) -> None:
        await self.delete(goal_id)

