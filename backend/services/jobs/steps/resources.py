"""Step 3: study resources, one goal at a time.

> "no, you cannot have resources without memory" (the user, 2026-09-23)

So this step refuses to run for a student the app has written nothing about: a
search made with no reading of the learner returns the same nine links anyone
would get, and storing those is worse than storing none. It is the reason the
chain is a chain and not three jobs fired together.

What it reads for each goal: the goal, the student's newest context, and the
links that goal already holds - the last so a second run is asked for something
new rather than for what is already on the screen.
"""

import logging
import uuid

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.language import Language
from backend.models.goal import Goal
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.services.gemini.client.gemini_guard import run_gemini_background
from backend.services.gemini.resources.search_resources import search_resources
from backend.services.jobs.steps.language import student_language
from backend.services.resources.found_pages import page_resources
from backend.services.resources.link_validation import validate_resources
from backend.services.resources.youtube_search import search_videos

logger = logging.getLogger(__name__)


async def run_resources_step(session: AsyncSession, student_id: uuid.UUID) -> int:
    """Search, verify and store resources for the student's active goal - a
    paused one is not refreshed (the user, 2026-09-26).
    Returns how many stuck. Returns 0 without calling Gemini when the app has
    no reading of this student."""
    contexts = await StudentContextRepository(session).list_valid(student_id)
    if not contexts:
        logger.info("Resources step: student %s has no context yet, skipping", student_id)
        return 0

    reading = f"{contexts[0].state} {contexts[0].metacognition}"
    goals = await GoalRepository(session).list_active(student_id)
    language = await student_language(session, student_id, goals)

    total = 0
    for goal in goals:
        total += await _resources_for_goal(session, goal, reading, language)
    return total


async def _resources_for_goal(
    session: AsyncSession, goal: Goal, reading: str, language: Language
) -> int:
    repository = ResourceRepository(session)
    held = [resource.link for resource in await repository.list_by_goal(goal.id)]

    # Nobody is waiting on it, so each of its calls retries on the background
    # budget (backend/services/gemini/client/gemini_retry.py).
    search = await run_gemini_background(
        search_resources,
        goal_name=goal.name or "",
        goal_description=goal.description or "",
        student_context=reading,
        existing_links=held,
        language=language,
    )
    async with httpx.AsyncClient() as client:
        videos = await search_videos(client, goal.id, search.video_query, language)
        found = page_resources(goal.id, search.pages) + videos
        logger.info("Found %d resources for goal %s", len(found), goal.id)
        verified = await validate_resources(found, client=client)

    # A page is only known by its address once its redirect is followed, and two
    # sources may land on one page: dedupe after validation, against the goal
    # and within the batch.
    already = await repository.existing_links(goal.id, [r.link for r in verified])
    fresh = []
    for resource in verified:
        if resource.link not in already:
            already.add(resource.link)
            fresh.append(resource)

    await repository.create_many(fresh)
    await session.commit()
    logger.info("Resources step: stored %d resources for goal %s", len(fresh), goal.id)
    return len(fresh)
