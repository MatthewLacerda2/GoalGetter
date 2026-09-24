import asyncio
import pytest
from unittest.mock import patch

from backend.models.goal import Goal
from backend.models.resource import Resource, StudyResourceType
from backend.repositories.lesson_question_repository import LessonQuestionRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.lesson.schema import GeminiLessonQuestionsResponse, LessonQuestionItem
from backend.services.gemini.student_context.schema import GeminiStudentContextResponse
from backend.services.jobs import goal_jobs
from backend.services.jobs.goal_jobs import generate_lessons, kickoff_lessons_generation, scrape_resources

MODULE = "backend.services.jobs.goal_jobs"


def resource(goal_id, link):
    return Resource(
        goal_id=goal_id,
        resource_type=StudyResourceType.webpage,
        name="Guide",
        description="A guide",
        language="en",
        link=link,
    )


@pytest.mark.asyncio
async def test_scraping_stores_only_the_verified_resources(test_db, test_user):
    """Gemini suggests two, validation keeps one, only that one is stored"""
    goal = Goal(name="Learn Italian", description="d", student_id=test_user.id)
    test_db.add(goal)
    await test_db.commit()
    await test_db.refresh(goal)
    goal_id = str(goal.id)

    good = resource(goal_id, "https://good.dev/a")
    bad = resource(goal_id, "https://dead.dev/b")

    with patch(MODULE + ".search_resources", return_value=[good, bad]), \
         patch(MODULE + ".validate_resources", return_value=[good]), \
         patch(MODULE + ".AsyncSessionLocal", return_value=_Session(test_db)):
        stored = await scrape_resources(goal_id)

    assert stored == 1
    links = [r.link for r in await ResourceRepository(test_db).list_by_goal(goal_id)]
    assert links == ["https://good.dev/a"]


@pytest.mark.asyncio
async def test_scraping_skips_a_deleted_goal(test_db):
    """The goal was deleted before the job ran: nothing is stored, nothing raises"""
    missing = "00000000-0000-0000-0000-0000000000ff"
    with patch(MODULE + ".search_resources") as search, \
         patch(MODULE + ".AsyncSessionLocal", return_value=_Session(test_db)):
        assert await scrape_resources(missing) == 0
    search.assert_not_called()


CONTEXT = GeminiStudentContextResponse(state="Beginner", metacognition="Curious", ai_model="m")
ANSWERS = [("Experience?", "None")]


def generated(*correct_indexes):
    return GeminiLessonQuestionsResponse(questions=[
        LessonQuestionItem(question=f"Q{i}", option_a="a", option_b="b", option_c="c",
                           option_d="d", correct_option_index=index)
        for i, index in enumerate(correct_indexes)
    ])


@pytest.mark.asyncio
async def test_lessons_job_stores_one_context_and_the_questions(test_db, test_user, goal_factory):
    """The onboarding reaches the context call; out-of-range questions are dropped"""
    goal = await goal_factory(test_user)
    with patch(MODULE + ".gemini_generate_student_context", return_value=CONTEXT) as context_call, \
         patch(MODULE + ".generate_lesson_questions", return_value=generated(0, 3, 4)) as questions_call, \
         patch(MODULE + ".AsyncSessionLocal", return_value=_Session(test_db)):
        stored = await generate_lessons(str(goal.id), "I want Italian", ANSWERS)

    assert stored == 2
    context_call.assert_called_once_with(goal.name, goal.description, "I want Italian", ANSWERS)
    questions_call.assert_called_once_with(goal.name, goal.description, 1200, "Beginner", "Curious")
    contexts = await StudentContextRepository(test_db).list_valid(test_user.id, goal.id)
    assert [(c.state, c.metacognition) for c in contexts] == [("Beginner", "Curious")]
    bank = await LessonQuestionRepository(test_db).list_bank_history(goal.id)
    assert sorted(h.question.question for h in bank) == ["Q0", "Q1"]


@pytest.mark.asyncio
async def test_lessons_job_skips_a_deleted_goal(test_db):
    missing = "00000000-0000-0000-0000-0000000000ff"
    with patch(MODULE + ".gemini_generate_student_context") as context_call, \
         patch(MODULE + ".AsyncSessionLocal", return_value=_Session(test_db)):
        assert await generate_lessons(missing, "p", ANSWERS) == 0
    context_call.assert_not_called()


@pytest.mark.asyncio
async def test_lessons_job_never_raises(test_db, test_user, goal_factory):
    """Gemini fails mid-job: the kickoff swallows and logs it, the context already stored stays"""
    goal = await goal_factory(test_user)
    with patch(MODULE + ".gemini_generate_student_context", return_value=CONTEXT), \
         patch(MODULE + ".generate_lesson_questions", side_effect=RuntimeError("quota")), \
         patch(MODULE + ".AsyncSessionLocal", return_value=_Session(test_db)):
        kickoff_lessons_generation(str(goal.id), "p", ANSWERS)
        await asyncio.gather(*goal_jobs._running)

    assert len(await StudentContextRepository(test_db).list_valid(test_user.id, goal.id)) == 1
    assert await LessonQuestionRepository(test_db).list_bank_history(goal.id) == []


class _Session:
    """Hands the job the test's session and keeps it open afterwards."""

    def __init__(self, session):
        self.session = session

    async def __aenter__(self):
        return self.session

    async def __aexit__(self, *exc):
        return False
