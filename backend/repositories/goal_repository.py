from typing import List, Optional
from sqlalchemy import select
from backend.models.goal import Goal
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
        from sqlalchemy import func, desc
        from backend.models.objective import Objective
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
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            await self.db.flush()
            return True
        return False

    async def delete_cascade(self, goal_id: str) -> None:
        from backend.models.player_achievement import PlayerAchievement
        from backend.models.resource import Resource
        from backend.models.student_context import StudentContext
        from backend.models.objective import Objective

        # Delete PlayerAchievements
        pa_stmt = select(PlayerAchievement).where(PlayerAchievement.goal_id == goal_id)
        pa_result = await self.db.execute(pa_stmt)
        for pa in pa_result.scalars().all():
            await self.db.delete(pa)

        # Delete Resources
        r_stmt = select(Resource).where(Resource.goal_id == goal_id)
        r_result = await self.db.execute(r_stmt)
        for resource in r_result.scalars().all():
            await self.db.delete(resource)

        # Delete StudentContexts
        sc_stmt = select(StudentContext).where(StudentContext.goal_id == goal_id)
        sc_result = await self.db.execute(sc_stmt)
        for sc in sc_result.scalars().all():
            await self.db.delete(sc)

        # Delete Objectives
        obj_stmt = select(Objective).where(Objective.goal_id == goal_id)
        obj_result = await self.db.execute(obj_stmt)
        for objective in obj_result.scalars().all():
            await self.db.delete(objective)

        # Flush to satisfy foreign key constraints before deleting the goal
        await self.db.flush()

        # Delete Goal
        await self.delete(goal_id)

