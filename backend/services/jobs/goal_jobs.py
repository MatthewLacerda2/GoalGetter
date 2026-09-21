"""Background work kicked off when a goal is created.

Both jobs are fire-and-forget: the goal-creation response returns immediately and
the introduction screens buy time while these run. They are also meant to run on
their own schedule later (resources: on a significant skill jump or monthly;
lessons: a daily check that skips users who did no lessons).

Nothing here is allowed to fail the request that started it, so every job is
wrapped and its errors are logged rather than raised.
"""
import asyncio
import logging

from backend.core.database import AsyncSessionLocal
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.services.gemini.resources.search_resources import search_resources
from backend.services.resources.link_validation import validate_resources

logger = logging.getLogger(__name__)


async def scrape_resources(goal_id: str) -> int:
    """Find, verify and store study resources for a goal. Returns how many stuck."""
    async with AsyncSessionLocal() as session:
        goal = await GoalRepository(session).get_by_id(goal_id)
        if goal is None:
            logger.warning("Resource scraping: goal %s no longer exists", goal_id)
            return 0

        # The Gemini client is synchronous and this is a slow, grounded search,
        # so keep it off the event loop.
        recommended = await asyncio.to_thread(
            search_resources, goal_id, goal.name, goal.description
        )
        logger.info("Gemini recommended %d resources for goal %s", len(recommended), goal_id)

        verified = await validate_resources(recommended)

        repository = ResourceRepository(session)
        already_stored = await repository.existing_links(goal_id, [r.link for r in verified])
        fresh = [r for r in verified if r.link not in already_stored]

        await repository.create_many(fresh)
        await session.commit()

    logger.info("Stored %d resources for goal %s", len(fresh), goal_id)
    return len(fresh)


async def generate_lessons(goal_id: str) -> int:
    """Generate the initial lesson bank for the goal."""
    # TODO: not built yet. Left as a no-op so the create flow stays wired.
    logger.info("TODO: lessons generation for goal %s", goal_id)
    return 0


async def _run_safely(name: str, coroutine) -> None:
    try:
        await coroutine
    except Exception:
        logger.exception("Background job %s failed", name)


def _spawn(name: str, coroutine) -> None:
    """Schedule a job on the running loop, keeping a reference so it is not
    garbage-collected mid-flight."""
    task = asyncio.create_task(_run_safely(name, coroutine))
    _running.add(task)
    task.add_done_callback(_running.discard)


_running: set[asyncio.Task] = set()


def kickoff_resource_scraping(goal_id: str) -> None:
    _spawn("resource scraping", scrape_resources(goal_id))


def kickoff_lessons_generation(goal_id: str) -> None:
    _spawn("lessons generation", generate_lessons(goal_id))
