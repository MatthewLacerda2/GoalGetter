from fastapi import APIRouter, Query
from backend.core.database import get_db
from backend.models.resource import Resource
from backend.schemas.resource import ResourceResponse
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends, status
from sqlalchemy import select

router = APIRouter()

@router.get("", response_model=ResourceResponse, status_code=status.HTTP_200_OK)
async def get_resources(
    goal_id: str = Query(..., description="Goal ID to filter resources by"),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all resources for a specific goal
    """
    #TODO: update this
    #We must show resources which match the objective,
    #and the student context (mostly, whether the resource is fit for a student of this level)
    stmt = select(Resource).where(Resource.goal_id == goal_id).order_by(Resource.resource_type, Resource.name)
    result = await db.execute(stmt)
    resources = result.scalars().all()
    
    return ResourceResponse(resources=resources)