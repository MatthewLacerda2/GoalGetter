import pytest
from unittest.mock import patch

from backend.models.goal import Goal
from backend.models.resource import Resource, StudyResourceType
from backend.repositories.resource_repository import ResourceRepository
from backend.services.jobs.goal_jobs import scrape_resources

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


class _Session:
    """Hands the job the test's session and keeps it open afterwards."""

    def __init__(self, session):
        self.session = session

    async def __aenter__(self):
        return self.session

    async def __aexit__(self, *exc):
        return False
