"""FastAPI dependencies that resolve a goal for the signed-in student.

Two ways an endpoint names its goal:

- implicitly, through the **active goal** (`students.current_goal_id`) — the
  goal-scoped reads: `/resources`, `/home`, `/tutor/*`;
- explicitly, by `goal_id` in the path — `/goals/{goal_id}/...`.

Both answer **404** when the goal is missing *or belongs to someone else*, so a
goal's existence never leaks to another student.
"""

from uuid import UUID

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from backend.api.v1.student_dependencies import get_current_user
from backend.core.database import get_db
from backend.core.errors.api_error import ApiError
from backend.core.errors.codes import ErrorCode
from backend.models.goal import Goal
from backend.models.student import Student
from backend.repositories.goal_repository import GoalRepository


async def get_active_goal(
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Goal:
    if current_user.current_goal_id is None:
        raise ApiError(ErrorCode.NO_ACTIVE_GOAL)
    goal = await GoalRepository(db).get_by_id(current_user.current_goal_id)
    if goal is None or goal.student_id != current_user.id:
        raise ApiError(ErrorCode.NO_ACTIVE_GOAL)
    return goal


async def get_owned_goal(
    goal_id: UUID,
    current_user: Student = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Goal:
    goal = await GoalRepository(db).get_by_id(goal_id)
    if goal is None or goal.student_id != current_user.id:
        raise ApiError(ErrorCode.GOAL_NOT_FOUND)
    return goal
