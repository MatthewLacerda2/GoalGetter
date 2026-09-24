from sqlalchemy import delete as sql_delete
from sqlalchemy import select

from backend.models.refresh_token import RefreshToken
from backend.repositories.base import BaseRepository


class RefreshTokenRepository(BaseRepository[RefreshToken]):
    async def create(self, entity: RefreshToken) -> RefreshToken:
        self.db.add(entity)
        await self.db.flush()
        return entity

    async def get_by_id(self, entity_id: str) -> RefreshToken | None:
        stmt = select(RefreshToken).where(RefreshToken.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_token(self, token: str) -> RefreshToken | None:
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
