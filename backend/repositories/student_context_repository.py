from typing import List, Optional
from sqlalchemy.orm import selectinload
from sqlalchemy import select, and_, desc, case
from backend.models.student_context import StudentContext
from backend.repositories.base import BaseRepository

class StudentContextRepository(BaseRepository[StudentContext]):
    
    async def create(self, entity: StudentContext) -> StudentContext:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[StudentContext]:
        stmt = select(StudentContext).where(StudentContext.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def update(self, entity: StudentContext) -> StudentContext:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
    
    async def get_by_student_id(self, student_id: str, limit: int = None) -> List[StudentContext]:
        """Get all valid student contexts for a specific student"""
        stmt = select(StudentContext).where(
            and_(
                StudentContext.student_id == student_id,
                StudentContext.is_still_valid == True
            )
        )
        if limit:
            stmt = stmt.limit(limit)
        stmt = stmt.order_by(desc(StudentContext.created_at))
        
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_by_student_and_objective(self, student_id: str, objective_id: str, limit: int) -> List[StudentContext]:
        """Get student contexts for a specific student and objective, ordered by created_at descending."""
        stmt = select(StudentContext).where(
            and_(
                StudentContext.student_id == student_id,
                StudentContext.objective_id == objective_id,
                StudentContext.is_still_valid == True
            )
        )
        stmt = stmt.order_by(desc(StudentContext.created_at))
        stmt = stmt.limit(limit)
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_with_relationships(self, context_id: str) -> Optional[StudentContext]:
        """Get a student context with all relationships loaded"""
        stmt = select(StudentContext).options(
            selectinload(StudentContext.student),
            selectinload(StudentContext.goal),
            selectinload(StudentContext.objective)
        ).where(StudentContext.id == context_id)
        
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_student_with_relationships(self, student_id: str, limit: int = None) -> List[StudentContext]:
        """Get student contexts with all relationships loaded"""
        stmt = select(StudentContext).options(
            selectinload(StudentContext.student),
            selectinload(StudentContext.goal),
            selectinload(StudentContext.objective)
        ).where(StudentContext.student_id == student_id)
        
        if limit:
            stmt = stmt.limit(limit)
        stmt = stmt.order_by(desc(StudentContext.created_at))
        
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_latest_for_evaluation(self, student_id: str, current_objective_id: str, limit: int = 8) -> List[StudentContext]:
        """
        Get latest valid student contexts for evaluation, ordered by latest objective first then created_at DESC.
        
        Args:
            student_id: The student's ID
            current_objective_id: The student's current objective ID
            limit: Maximum number of contexts to return (default: 8)
        
        Returns:
            List of StudentContext ordered by objective_id (current objective first), then created_at DESC
        """
        # Order by objective_id (current objective first using CASE), then by created_at DESC
        # Use CASE to prioritize current objective (0) over others (1)
        objective_order = case(
            (StudentContext.objective_id == current_objective_id, 0),
            else_=1
        )
        
        stmt = select(StudentContext).where(
            and_(
                StudentContext.student_id == student_id,
                StudentContext.is_still_valid == True
            )
        ).order_by(
            objective_order,
            desc(StudentContext.created_at)
        ).limit(limit)
        
        result = await self.db.execute(stmt)
        return list(result.scalars().all())