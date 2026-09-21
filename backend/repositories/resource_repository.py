from typing import Optional

from sqlalchemy import select, delete as sql_delete

from backend.models.resource import Resource
from backend.repositories.base import BaseRepository


class ResourceRepository(BaseRepository[Resource]):

    async def create(self, entity: Resource) -> Resource:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def create_many(self, entities: list[Resource]) -> list[Resource]:
        if not entities:
            return []
        self.db.add_all(entities)
        await self.db.flush()
        return entities

    async def get_by_id(self, entity_id: str) -> Optional[Resource]:
        stmt = select(Resource).where(Resource.id == entity_id)
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_goal(self, goal_id: str) -> list[Resource]:
        stmt = select(Resource).where(Resource.goal_id == goal_id)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def existing_links(self, goal_id: str, links: list[str]) -> set[str]:
        """Which of these links this goal already holds.

        Scoped to the goal on purpose: the same link under a different goal is
        fine and expected, we only avoid storing a duplicate twice for one goal.
        """
        if not links:
            return set()
        stmt = select(Resource.link).where(
            Resource.goal_id == goal_id, Resource.link.in_(links)
        )
        result = await self.db.execute(stmt)
        return set(result.scalars().all())

    async def update(self, entity: Resource) -> Resource:
        await self.db.flush()
        return entity

    async def delete(self, entity_id: str) -> bool:
        stmt = sql_delete(Resource).where(Resource.id == entity_id)
        result = await self.db.execute(stmt)
        return result.rowcount > 0
