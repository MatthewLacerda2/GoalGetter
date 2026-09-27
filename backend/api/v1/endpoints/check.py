"""The health check: docker-compose.yml's healthcheck calls it, and
core/logging_middleware.py leaves it out of the log."""

from fastapi import APIRouter

router = APIRouter()


@router.get("")
async def root() -> dict[str, str]:
    return {"message": "Welcome to GoalGetter API"}
