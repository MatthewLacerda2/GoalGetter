import uuid

from sqlalchemy import select

from backend.models.resource import Resource
from backend.repositories.base import BaseRepository


class ResourceRepository(BaseRepository[Resource]):
    model = Resource

    async def create_many(self, entities: list[Resource]) -> list[Resource]:
        if not entities:
            return []
        self.db.add_all(entities)
        await self.db.flush()
        return entities

    async def list_by_goal(self, goal_id: uuid.UUID) -> list[Resource]:
        stmt = select(Resource).where(Resource.goal_id == goal_id)
        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def existing_links(self, goal_id: uuid.UUID, links: list[str]) -> set[str]:
        """Which of these links this goal already holds.

        Scoped to the goal on purpose: the same link under a different goal is
        fine and expected, we only avoid storing a duplicate twice for one goal.
        """
        if not links:
            return set()
        stmt = select(Resource.link).where(Resource.goal_id == goal_id, Resource.link.in_(links))
        result = await self.db.execute(stmt)
        return set(result.scalars().all())

    async def list_missing_embeddings(self, limit: int) -> list[Resource]:
        """Resources whose description embedding is still null, oldest first (#96).

        The resource search already embeds what it stores, so this normally
        finds only what that call could not finish - which is the whole point
        of a backfill keyed on null.
        """
        stmt = (
            select(Resource)
            .where(Resource.description_embedding.is_(None))
            .order_by(Resource.created_at, Resource.id)
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        return list(result.scalars().all())
