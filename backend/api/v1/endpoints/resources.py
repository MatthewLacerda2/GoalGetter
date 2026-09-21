from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from backend.api.v1.goal_dependencies import get_active_goal
from backend.core.database import get_db
from backend.models.goal import Goal
from backend.models.resource import StudyResourceType
from backend.repositories.resource_repository import ResourceRepository
from backend.schemas.resource import ResourceItem, ResourcesResponse

router = APIRouter()

# The stored resource type -> the group the resources screen shows it under.
GROUP_BY_TYPE = {
    StudyResourceType.youtube: "youtube",
    StudyResourceType.pdf: "books",
    StudyResourceType.webpage: "websites",
}


@router.get("", response_model=ResourcesResponse)
async def list_resources(
    goal: Goal = Depends(get_active_goal),
    db: AsyncSession = Depends(get_db),
):
    """The active goal's curated resources, grouped by kind. No active goal is 404;
    a goal whose background search has not finished yet has three empty lists."""
    groups: dict[str, list[ResourceItem]] = {group: [] for group in GROUP_BY_TYPE.values()}
    for resource in await ResourceRepository(db).list_by_goal(goal.id):
        groups[GROUP_BY_TYPE[resource.resource_type]].append(ResourceItem(
            name=resource.name,
            description=resource.description,
            url=resource.link,
            image_url=resource.image_url,
        ))
    return ResourcesResponse(**groups)
