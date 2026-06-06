from typing import Optional
from sqlalchemy import select, update as sql_update, delete as sql_delete
from backend.models.refresh_token import RefreshToken
from backend.repositories.base import BaseRepository

class RefreshTokenRepository(BaseRepository[RefreshToken]):
    
    async def create(self, entity: RefreshToken) -> RefreshToken:
        self.db.add(entity)
        await self.db.flush()
        return entity
    
    async def get_by_id(self, entity_id: str) -> Optional[RefreshToken]:
        stmt = select(RefreshToken).where(RefreshToken.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def get_by_token(self, token: str) -> Optional[RefreshToken]:
        stmt = select(RefreshToken).where(RefreshToken.token == token)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()
    
    async def update(self, entity: RefreshToken) -> RefreshToken:
        await self.db.flush()
        return entity
    
    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(RefreshToken).where(RefreshToken.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0

    async def revoke_all_for_student(self, student_id: str) -> None:
        stmt = (
            sql_update(RefreshToken)
            .where(RefreshToken.student_id == student_id)
            .values(revoked=True)
        )
        await self.db.execute(stmt)
