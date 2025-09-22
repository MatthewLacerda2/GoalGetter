from typing import List, Optional, Tuple
from sqlalchemy.orm import selectinload
from sqlalchemy import select, and_, desc, asc
from backend.models.student import Student
from backend.repositories.base import BaseRepository

class StudentRepository(BaseRepository[Student]):
    
    async def create(self, entity: Student) -> Student:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[Student]:
        stmt = select(Student).where(Student.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_google_id(self, google_id: str) -> Optional[Student]:
        stmt = select(Student).where(Student.google_id == google_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_email(self, email: str) -> Optional[Student]:
        stmt = select(Student).where(Student.email == email)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def update(self, entity: Student) -> Student:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
    
    async def get_leaderboard_around_user(self, user_id: str, limit: int = 10) -> Tuple[Optional[Student], List[Student]]:
        """
        Get the current user and 10 users above and below their XP level.
        Only includes users who have completed onboarding (have objectives).
        Returns a tuple of (current_user, leaderboard_users)
        """
        # First, get the current user with their goal and current_objective information
        current_user_stmt = select(Student).options(
            selectinload(Student.goal),
            selectinload(Student.current_objective)
        ).where(Student.id == user_id)
        
        current_user_result = await self.db.execute(current_user_stmt)
        current_user = current_user_result.scalar_one_or_none()
        
        if not current_user or not current_user.current_objective_id:
            return None, []
        
        current_xp = current_user.overall_xp
        
        # Get the users right above in the leaderboard
        above_stmt = select(Student).options(
            selectinload(Student.goal),
            selectinload(Student.current_objective)
        ).where(
            and_(
                Student.overall_xp > current_xp,
                Student.id != user_id,
                Student.current_objective_id.isnot(None)
            )
        ).order_by(asc(Student.overall_xp)).limit(limit)        
        above_result = await self.db.execute(above_stmt)
        users_above = above_result.scalars().all()
        
        # Get the users right below in the leaderboard
        below_stmt = select(Student).options(
            selectinload(Student.goal),
            selectinload(Student.current_objective)
        ).where(
            and_(
                Student.overall_xp < current_xp,
                Student.id != user_id,
                Student.current_objective_id.isnot(None)
            )
        ).order_by(desc(Student.overall_xp)).limit(limit)        
        below_result = await self.db.execute(below_stmt)
        users_below = below_result.scalars().all()
        
        leaderboard_users = list(users_above) + [current_user] + list(users_below)
        
        return current_user, leaderboard_users
    
    async def get_user_with_goal(self, user_id: str) -> Optional[Student]:
        """Get a user with their goal information loaded"""
        stmt = select(Student).options(
            selectinload(Student.goal)
        ).where(Student.id == user_id)
        
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()