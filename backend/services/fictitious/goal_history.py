"""One goal's lived-in history, written through the repositories: its question
bank, the answers of past lessons, tutor chat, resources and student context.
The content is hardcoded in history_data.py.

A lesson here is what it is everywhere else since #131 - a batch of answers
sharing one minted `lesson_id`. Nothing is written for the lessons themselves,
so the goal's rating is the only place the seeded elo lands - and it is not
invented either (#62): once the answers are written, the goal's rating is what
replaying them says, exactly as a real submission would have left it."""

import uuid
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core import clock
from backend.models.chat_message import ChatMessage
from backend.models.goal import Goal
from backend.models.question import Question
from backend.models.resource import Resource, StudyResourceType
from backend.models.student import Student
from backend.models.student_answer import StudentAnswer
from backend.models.student_context import StudentContext
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.question_repository import QuestionRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_answer_repository import StudentAnswerRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.fictitious.history_data import LESSON_SIZE, START_RATING
from backend.services.lessons.rasch import replay


def moment(now: datetime, days_ago: int, hour: int | None, minute: int = 0) -> datetime:
    """An aware moment `days_ago` days before `now`, at `hour:minute` on the
    app's wall clock (#92) - the hours in history_data are the student's, so
    22:00 has to be 22:00 in APP_TIMEZONE and not in whatever zone the seeder
    happens to run in. `hour=None` means "today, a moment ago": `30 - minute`
    minutes before now, so a lesson (minute 0) lands before the chat about it
    (minute 20)."""
    if hour is None:
        return now - timedelta(minutes=30 - minute)
    return clock.app_moment(clock.app_date(now) - timedelta(days=days_ago), hour, minute)


@dataclass
class PlannedLesson:
    answered_at: datetime
    question_indexes: list[int]
    correct: int


def plan_lessons(plan: list, bank_size: int, now: datetime) -> list[PlannedLesson]:
    """The lessons in order: when each was answered, which questions it served,
    and how many of them went right. Questions rotate through the bank. No elo
    here any more - the rating is read off the answers once they exist (#62)."""
    size = min(LESSON_SIZE, bank_size)
    planned = []
    for i, (days_ago, hour, correct) in enumerate(plan):
        planned.append(
            PlannedLesson(
                answered_at=moment(now, days_ago, hour),
                question_indexes=[(i * size + k) % bank_size for k in range(size)],
                correct=min(correct, size),
            )
        )
    return planned


async def _seed_lessons(db: AsyncSession, bank: list[Question], planned: list[PlannedLesson]):
    """Each lesson as one batch of answers under a minted `lesson_id`: the first
    `correct` right, the rest wrong. Answer times are made up but add up to the
    lesson's."""
    answers = StudentAnswerRepository(db)
    for i, plan in enumerate(planned):
        served = [bank[k] for k in plan.question_indexes]
        seconds = [8 + (k * 7 + i * 3) % 20 for k in range(len(served))]
        started = plan.answered_at - timedelta(seconds=sum(seconds))
        lesson_id = uuid.uuid4()
        await answers.create_many(
            [
                StudentAnswer(
                    lesson_id=lesson_id,
                    position=k,
                    question_id=q.id,
                    selected_index=q.right_answer_index
                    if k < plan.correct
                    else (q.right_answer_index + 1) % 4,
                    total_seconds=seconds[k],
                    created_at=started + timedelta(seconds=sum(seconds[: k + 1])),
                )
                for k, q in enumerate(served)
            ]
        )


async def _seed_rating(db: AsyncSession, goal: Goal, bank: list[Question]):
    """The rating the seeded answers actually earn (#62).

    `updated_at` is assigned explicitly so the column's ORM `onupdate` does not
    stamp this UPDATE with now: the goals list reads it as "last studied", and
    for this student that was the last seeded lesson, not the seeding.
    """
    history = await StudentAnswerRepository(db).list_history_by_goal(goal.id)
    goal.rating = replay(bank, history, start=START_RATING).rating
    goal.updated_at = history[-1].answered_at if history else goal.updated_at
    await GoalRepository(db).update(goal)


async def seed_goal(db: AsyncSession, student: Student, spec: dict, now: datetime) -> Goal:
    """Create one goal of history_data.GOALS with everything under it."""
    created = moment(now, spec["created_days_ago"], 18)
    planned = plan_lessons(spec["lessons"], len(spec["questions"]), now)
    goal = await GoalRepository(db).create(
        Goal(
            student_id=student.id,
            name=spec["name"],
            description=spec["description"],
            rating=START_RATING,
            created_at=created,
            updated_at=planned[-1].answered_at if planned else created,
        )
    )
    bank = await QuestionRepository(db).create_many(
        [
            Question(
                goal_id=goal.id,
                text=text,
                option_a=options[0],
                option_b=options[1],
                option_c=options[2],
                option_d=options[3],
                right_answer_index=correct,
                created_at=created + timedelta(minutes=5, seconds=i),
            )
            for i, (text, options, correct) in enumerate(spec["questions"])
        ]
    )
    await _seed_lessons(db, bank, planned)
    await _seed_rating(db, goal, bank)
    chat = ChatMessageRepository(db)
    for prompt, replies, liked, days_ago, hour in spec["chat"]:
        await chat.create(
            ChatMessage(
                student_id=student.id,
                goal_id=goal.id,
                prompt=prompt,
                tutor_responses=replies,
                is_liked=liked,
                created_at=moment(now, days_ago, hour, minute=20),
            )
        )
    await ResourceRepository(db).create_many(
        [
            Resource(
                goal_id=goal.id,
                resource_type=StudyResourceType(kind),
                name=name,
                description=description,
                language=language,
                link=link,
                created_at=created + timedelta(minutes=10),
            )
            for kind, name, description, language, link in spec["resources"]
        ]
    )
    if spec["context"]:
        state, metacognition = spec["context"]
        await StudentContextRepository(db).create(
            StudentContext(
                student_id=student.id,
                state=state,
                metacognition=metacognition,
                created_at=moment(now, 1, 22),
            )
        )
    return goal
