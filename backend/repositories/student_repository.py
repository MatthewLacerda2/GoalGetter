from typing import Optional
from sqlalchemy import select, delete as sql_delete
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
        stmt = sql_delete(Student).where(Student.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0