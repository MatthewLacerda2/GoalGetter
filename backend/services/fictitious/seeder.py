"""`make claude`: Fictitious Claude with a lived-in history (#60).

Idempotent: the history is written in one transaction, so a student with any
goal already has all of it, and a re-run leaves it untouched. `fresh=True`
deletes the student first; the database cascades take everything under it
(goals, lessons, answers, chat, contexts, refresh tokens).
"""

from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from backend.models.goal import Goal
from backend.models.student import Student
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.student_repository import StudentRepository
from backend.services.fictitious.goal_history import seed_goal
from backend.services.fictitious.history_data import GOALS, STUDENT_CREATED_DAYS_AGO
from backend.services.fictitious.identity import fictitious_identity

# The name POST /auth/dev-login receives from `make claude-token`.
CLAUDE = "Claude"


@dataclass
class SeedResult:
    student: Student
    created: bool  # False when the history was already there (a no-op run)
    goals: list[Goal]


async def seed_fictitious_student(
    db: AsyncSession, name: str = CLAUDE, fresh: bool = False, now: datetime | None = None
) -> SeedResult:
    """Ensure the fictitious student `name` exists with its history, and commit."""
    now = now or datetime.now().astimezone()
    identity = fictitious_identity(name)
    students, goals = StudentRepository(db), GoalRepository(db)
    student = await students.get_by_google_id(identity.google_id)
    if student and fresh:
        await students.delete(student.id)
        await db.commit()
        student = None
    if student:
        existing = await goals.list_by_student(student.id)
        if existing:
            return SeedResult(student=student, created=False, goals=existing)
    else:
        # A student dev-login already made is reused as is: same id, same tokens.
        student = await students.create(
            Student(
                name=identity.name,
                google_id=identity.google_id,
                email=identity.email,
            )
        )

    student.created_at = now - timedelta(days=STUDENT_CREATED_DAYS_AGO)
    seeded = []
    for spec in GOALS:
        goal = await seed_goal(db, student, spec, now)
        if spec["active"]:
            student.current_goal_id = goal.id
        seeded.append(goal)
    await students.update(student)
    await db.commit()
    return SeedResult(student=student, created=True, goals=seeded)
