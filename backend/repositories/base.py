from abc import ABC, abstractmethod
from typing import Generic, TypeVar

from sqlalchemy.ext.asyncio import AsyncSession

T = TypeVar("T")


class BaseRepository(Generic[T], ABC):
    def __init__(self, db: AsyncSession):
        self.db = db

    @abstractmethod
    async def create(self, entity: T) -> T:
        pass

    @abstractmethod
    async def get_by_id(self, entity_id: str) -> T | None:
        pass

    @abstractmethod
    async def update(self, entity: T) -> T:
        pass

    @abstractmethod
    async def delete(self, entity_id: str) -> bool:
        pass
