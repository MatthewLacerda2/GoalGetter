import logging
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc, and_
from sqlalchemy.orm import joinedload
from fastapi import APIRouter, Depends, HTTPException, status
from backend.core.database import get_db
from backend.core.security import get_current_user
from backend.models.student import Student
from backend.models.goal import Goal
from backend.models.objective import Objective
from backend.models.player_achievement import PlayerAchievement
from backend.models.resource import Resource
from backend.models.student_context import StudentContext
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.objective_repository import ObjectiveRepository
from backend.repositories.student_repository import StudentRepository
from backend.schemas.goal import ListGoalsResponse, GoalListItem
from backend.schemas.student import StudentCurrentStatusResponse

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get(
    "",
    response_model=ListGoalsResponse,
    status_code=status.HTTP_200_OK,
    description="List all goals for the current student, ordered by latest objective update"
)
async def list_goals(
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Get all goals for the current student, ordered by the last_updated_at of their latest objective"""
    
    # Query goals with their latest objective's last_updated_at
    # Join with objectives, group by goal, order by MAX(objectives.last_updated_at) DESC
    stmt = (
        select(
            Goal,
            func.max(Objective.last_updated_at).label('latest_objective_update')
        )
        .join(Objective, Goal.id == Objective.goal_id, isouter=False)
        .where(Goal.student_id == current_user.id)
        .group_by(Goal.id)
        .order_by(desc(func.max(Objective.last_updated_at)))
    )
    
    result = await db.execute(stmt)
    goals_with_updates = result.all()
    
    # If a goal has no objectives, we need to handle it separately
    # Get all goals for the student
    all_goals_stmt = select(Goal).where(Goal.student_id == current_user.id)
    all_goals_result = await db.execute(all_goals_stmt)
    all_goals = all_goals_result.scalars().all()
    
    # Find goals with no objectives
    goals_with_objectives = {goal.id for goal, _ in goals_with_updates}
    goals_without_objectives = [g for g in all_goals if g.id not in goals_with_objectives]
    
    # Combine results: goals with objectives (sorted by latest update), then goals without objectives (by created_at)
    goals_list = []
    
    # Add goals with objectives (already sorted)
    for goal, _ in goals_with_updates:
        goals_list.append(GoalListItem(
            id=str(goal.id),
            name=goal.name or "",
            description=goal.description or "",
            created_at=goal.created_at
        ))
    
    # Add goals without objectives (sorted by created_at DESC)
    for goal in sorted(goals_without_objectives, key=lambda g: g.created_at, reverse=True):
        goals_list.append(GoalListItem(
            id=str(goal.id),
            name=goal.name or "",
            description=goal.description or "",
            created_at=goal.created_at
        ))
    
    return ListGoalsResponse(goals=goals_list)


@router.put(
    "/{goal_id}/set-active",
    response_model=StudentCurrentStatusResponse,
    status_code=status.HTTP_200_OK,
    description="Set a goal as the active goal for the current student"
)
async def set_active_goal(
    goal_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Set the active goal and objective for the current student"""
    
    # Verify the goal belongs to the current student
    goal_repo = GoalRepository(db)
    goal = await goal_repo.get_by_id(goal_id)
    
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found"
        )
    
    if goal.student_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Goal does not belong to the current student"
        )
    
    # Get the latest objective for this goal (most recent by created_at)
    objective_repo = ObjectiveRepository(db)
    latest_objective = await objective_repo.get_latest_by_goal_id(goal_id)
    
    if not latest_objective:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No objectives found for this goal"
        )
    
    # Update student's active goal and objective
    student_repo = StudentRepository(db)
    current_user.goal_id = goal.id
    current_user.goal_name = goal.name or ""
    current_user.current_objective_id = latest_objective.id
    current_user.current_objective_name = latest_objective.name
    
    await student_repo.update(current_user)
    await db.commit()
    await db.refresh(current_user)
    
    return StudentCurrentStatusResponse(
        student_id=str(current_user.id),
        student_name=current_user.name,
        student_email=current_user.email,
        current_streak=current_user.current_streak,
        overall_xp=current_user.overall_xp,
        goal_id=str(current_user.goal_id) if current_user.goal_id else None,
        goal_name=current_user.goal_name,
    )


@router.delete(
    "/{goal_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    description="Delete a goal for the current student"
)
async def delete_goal(
    goal_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: Student = Depends(get_current_user)
):
    """Delete a goal and all its associated objectives. Does NOT decrement student.overall_xp"""
    
    # Verify the goal belongs to the current student
    goal_repo = GoalRepository(db)
    goal = await goal_repo.get_by_id(goal_id)
    
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found"
        )
    
    if goal.student_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Goal does not belong to the current student"
        )
    
    # Check if this goal is the current_user's active goal
    # Since each goal belongs to only one student, only current_user could have it as active
    student_repo = StudentRepository(db)
    is_active_goal = current_user.goal_id == goal.id
    
    if is_active_goal:
        # Find the most recently updated objective for this student
        # Join Objective with Goal to filter by student_id, excluding the goal we're about to delete
        stmt = (
            select(Objective)
            .join(Goal, Objective.goal_id == Goal.id)
            .where(
                and_(
                    Goal.student_id == current_user.id,
                    Goal.id != goal_id  # Exclude the goal we're about to delete
                )
            )
            .order_by(desc(Objective.last_updated_at))
            .limit(1)
            .options(joinedload(Objective.goal))
        )
        result = await db.execute(stmt)
        latest_objective = result.unique().scalar_one_or_none()
        
        if latest_objective and latest_objective.goal:
            # Set the goal of the most recently updated objective as the new active goal
            current_user.goal_id = latest_objective.goal.id
            current_user.goal_name = latest_objective.goal.name
            current_user.current_objective_id = latest_objective.id
            current_user.current_objective_name = latest_objective.name
        else:
            # No objectives left, set to NULL
            current_user.goal_id = None
            current_user.goal_name = None
            current_user.current_objective_id = None
            current_user.current_objective_name = None
        
        await student_repo.update(current_user)
        await db.flush()  # Flush to ensure foreign key constraint is satisfied
    
    # Delete related records before deleting the goal
    # Delete player achievements
    player_achievements_stmt = select(PlayerAchievement).where(PlayerAchievement.goal_id == goal_id)
    player_achievements_result = await db.execute(player_achievements_stmt)
    player_achievements = player_achievements_result.scalars().all()
    for pa in player_achievements:
        await db.delete(pa)
    
    # Delete resources
    resources_stmt = select(Resource).where(Resource.goal_id == goal_id)
    resources_result = await db.execute(resources_stmt)
    resources = resources_result.scalars().all()
    for resource in resources:
        await db.delete(resource)
    
    # Delete student contexts
    student_contexts_stmt = select(StudentContext).where(StudentContext.goal_id == goal_id)
    student_contexts_result = await db.execute(student_contexts_stmt)
    student_contexts = student_contexts_result.scalars().all()
    for sc in student_contexts:
        await db.delete(sc)
    
    # Delete objectives
    objectives_stmt = select(Objective).where(Objective.goal_id == goal_id)
    objectives_result = await db.execute(objectives_stmt)
    objectives = objectives_result.scalars().all()
    for objective in objectives:
        await db.delete(objective)
    
    await db.flush()
    
    # Delete the goal using the repository
    await goal_repo.delete(goal_id)
    await db.commit()
    
    return None
