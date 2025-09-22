from typing import List, Optional
from sqlalchemy import select, and_, desc
from datetime import datetime, timedelta
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
        # Calculate the start date (X days ago)
        start_date = datetime.now() - timedelta(days=days)
        
        stmt = select(StreakDay).where(
            and_(
                StreakDay.student_id == student_id,
                StreakDay.date_time >= start_date
            )
        ).order_by(desc(StreakDay.date_time))
        
        result = await self.db.execute(stmt)
        return result.scalars().all()