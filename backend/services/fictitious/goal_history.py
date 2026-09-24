"""One goal's lived-in history, written through the repositories: its question
bank, finished lessons with their answers, tutor chat, resources and student
context. The content is hardcoded in history_data.py."""

from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy.ext.asyncio import AsyncSession

from backend.core import clock
from backend.models.chat_message import ChatMessage
from backend.models.goal import Goal
from backend.models.lesson import Lesson
from backend.models.lesson_answer import LessonAnswer
from backend.models.lesson_question import LessonQuestion
from backend.models.resource import Resource, StudyResourceType
from backend.models.student import Student
from backend.models.student_context import StudentContext
from backend.repositories.chat_message_repository import ChatMessageRepository
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.lesson_answer_repository import LessonAnswerRepository
from backend.repositories.lesson_question_repository import LessonQuestionRepository
from backend.repositories.lesson_repository import LessonRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.fictitious.history_data import LESSON_SIZE, START_RATING


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


def elo_delta(accuracy: float) -> int:
    """A plausible delta for the fixture: +20 at 100%, -20 at 0%. The live app's
    delta is random for now (services/lessons/elo.py); a fixture that tracks
    accuracy reads better on Home."""
    return round((accuracy - 50) * 0.4)


@dataclass
class PlannedLesson:
    finished_at: datetime
    question_indexes: list[int]
    correct: int
    accuracy: float
    elo_delta: int
    elo_after: int


def plan_lessons(plan: list, bank_size: int, now: datetime) -> list[PlannedLesson]:
    """The lessons in order, with the elo series following from the deltas, so
    the last `elo_after` is START_RATING plus every delta. Questions rotate
    through the bank."""
    size = min(LESSON_SIZE, bank_size)
    elo, planned = START_RATING, []
    for i, (days_ago, hour, correct) in enumerate(plan):
        correct = min(correct, size)
        accuracy = round(100 * correct / size, 1)
        delta = elo_delta(accuracy)
        elo += delta
        planned.append(
            PlannedLesson(
                finished_at=moment(now, days_ago, hour),
                question_indexes=[(i * size + k) % bank_size for k in range(size)],
                correct=correct,
                accuracy=accuracy,
                elo_delta=delta,
                elo_after=elo,
            )
        )
    return planned


async def _seed_lessons(
    db: AsyncSession, goal: Goal, bank: list[LessonQuestion], planned: list[PlannedLesson]
):
    """Each lesson with one answer per served question: the first `correct`
    right, the rest wrong. Answer times are made up but add up to the lesson's."""
    lessons, answers = LessonRepository(db), LessonAnswerRepository(db)
    for i, plan in enumerate(planned):
        served = [bank[k] for k in plan.question_indexes]
        seconds = [8 + (k * 7 + i * 3) % 20 for k in range(len(served))]
        started = plan.finished_at - timedelta(seconds=sum(seconds))
        lesson = await lessons.create(
            Lesson(
                goal_id=goal.id,
                created_at=started,
                question_ids=[q.id for q in served],
                finished_at=plan.finished_at,
                total_seconds=sum(seconds),
                accuracy=plan.accuracy,
                elo_delta=plan.elo_delta,
                elo_after=plan.elo_after,
            )
        )
        await answers.create_many(
            [
                LessonAnswer(
                    lesson_id=lesson.id,
                    question_id=q.id,
                    is_correct=k < plan.correct,
                    selected_option_index=q.correct_option_index
                    if k < plan.correct
                    else (q.correct_option_index + 1) % 4,
                    time_spent=seconds[k],
                    created_at=started + timedelta(seconds=sum(seconds[: k + 1])),
                )
                for k, q in enumerate(served)
            ]
        )


async def seed_goal(db: AsyncSession, student: Student, spec: dict, now: datetime) -> Goal:
    """Create one goal of history_data.GOALS with everything under it."""
    created = moment(now, spec["created_days_ago"], 18)
    planned = plan_lessons(spec["lessons"], len(spec["questions"]), now)
    goal = await GoalRepository(db).create(
        Goal(
            student_id=student.id,
            name=spec["name"],
            description=spec["description"],
            rating=planned[-1].elo_after if planned else START_RATING,
            created_at=created,
            updated_at=planned[-1].finished_at if planned else created,
        )
    )
    bank = await LessonQuestionRepository(db).create_many(
        [
            LessonQuestion(
                goal_id=goal.id,
                question=text,
                option_a=options[0],
                option_b=options[1],
                option_c=options[2],
                option_d=options[3],
                correct_option_index=correct,
                created_at=created + timedelta(minutes=5, seconds=i),
            )
            for i, (text, options, correct) in enumerate(spec["questions"])
        ]
    )
    await _seed_lessons(db, goal, bank, planned)
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
