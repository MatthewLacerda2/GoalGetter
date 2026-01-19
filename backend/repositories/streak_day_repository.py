from typing import List, Optional
from sqlalchemy import select, and_, desc
from datetime import datetime, timedelta, timezone
from backend.models.streak_day import StreakDay
from backend.repositories.base import BaseRepository

class StreakDayRepository(BaseRepository[StreakDay]):
    
    async def create(self, entity: StreakDay) -> StreakDay:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[StreakDay]:
        stmt = select(StreakDay).where(StreakDay.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def update(self, entity: StreakDay) -> StreakDay:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        entity = await self.get_by_id(entity_id)
        if entity:
            await self.db.delete(entity)
            return True
        return False
    
    async def get_by_student_id_and_days(self, student_id: str, days: int) -> List[StreakDay]:
        """
        Get streak days for a specific student within the last X days
        """
        start_date = datetime.now() - timedelta(days=days)        
        stmt = select(StreakDay).where(
            and_(
                StreakDay.student_id == student_id,
                StreakDay.date_time >= start_date
            )
        ).order_by(desc(StreakDay.date_time))
        
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_by_student_id_and_date_range(self, student_id: str, start_date: datetime, end_date: datetime) -> List[StreakDay]:
        """
        Get streak days for a specific student within a date range
        """
        stmt = select(StreakDay).where(
            and_(
                StreakDay.student_id == student_id,
                StreakDay.date_time >= start_date,
                StreakDay.date_time <= end_date
            )
        ).order_by(desc(StreakDay.date_time))
        
        result = await self.db.execute(stmt)
        return result.scalars().all()
    
    async def get_by_student_id_and_date(self, student_id: str, target_date: datetime) -> Optional[StreakDay]:
        """
        Get streak day for a specific student on a specific calendar date.
        The target_date can be any datetime, and this method will find a streak day
        that falls on the same calendar day (ignoring time).
        """
        # Normalize target_date to start of day in UTC
        if target_date.tzinfo is None:
            target_date = target_date.replace(tzinfo=timezone.utc)
        start_of_day = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_of_day = start_of_day + timedelta(days=1) - timedelta(microseconds=1)
        
        stmt = select(StreakDay).where(
            and_(
                StreakDay.student_id == student_id,
                StreakDay.date_time >= start_of_day,
                StreakDay.date_time <= end_of_day
            )
        ).order_by(desc(StreakDay.date_time))
        
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()