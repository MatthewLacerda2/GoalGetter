import uuid

from sqlalchemy import delete as sql_delete
from sqlalchemy import inspect
from sqlalchemy.ext.asyncio import AsyncSession

from backend.models.base import Base


class BaseRepository[T: Base]:
    """What every repository does the same way, written once (#208).

    A repository names its model (`model = Student`) and inherits `create`,
    `get_by_id` and `update`; it writes only the queries particular to its table,
    or overrides one of these when the table asks for more (`GoalRepository.create`
    writes the goal's first frontier with it).

    **Deleting is not here.** Most tables are never deleted from on purpose - a
    frontier, a student context and an answer are history, and a goal's rows go
    with the goal through ON DELETE CASCADE. A base that required `delete` made the
    append-only `frontiers` implement it by raising; a table whose rows *are*
    deleted says so by extending `DeletableRepository`, so "this table is
    append-only" is the absence of a method, not a method that fails.
    """

    model: type[T]

    def __init__(self, db: AsyncSession):
        self.db = db

    async def create(self, entity: T) -> T:
        self.db.add(entity)
        await self.db.flush()
        await self.db.refresh(entity)
        return entity

    async def get_by_id(self, entity_id: uuid.UUID) -> T | None:
        return await self.db.get(self.model, entity_id)

    async def update(self, entity: T) -> T:
        """Flush the changes already made on the entity."""
        await self.db.flush()
        return entity


class DeletableRepository[T: Base](BaseRepository[T]):
    """A repository whose rows the app deletes: a student (his account) and a goal."""

    async def delete(self, entity_id: uuid.UUID) -> bool:
        """Delete by primary key in SQL, so the database's ON DELETE CASCADE takes
        the children instead of the ORM loading them first. False when no row
        had that id."""
        key = inspect(self.model).primary_key[0]
        stmt = sql_delete(self.model).where(key == entity_id).returning(key)
        result = await self.db.execute(stmt)
        return result.first() is not None
