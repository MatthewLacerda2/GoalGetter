from fastapi import APIRouter, Query, Depends, status
from backend.core.database import get_db
from backend.models.resource import Resource
from backend.schemas.resource import ResourceResponse
from backend.repositories.resource_repository import ResourceRepository
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

@router.get("", response_model=ResourceResponse, status_code=status.HTTP_200_OK)
async def get_resources(
    goal_id: str = Query(..., description="Goal ID to filter resources by"),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all resources for a specific goal
    """
    resource_repo = ResourceRepository(db)
    resources = await resource_repo.get_by_goal_id(goal_id)
    
    return ResourceResponse(resources=resources)