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

import httpx

from backend.core.language import Language
from backend.repositories.goal_repository import GoalRepository
from backend.repositories.resource_repository import ResourceRepository
from backend.repositories.student_context_repository import StudentContextRepository
from backend.repositories.student_repository import StudentRepository
from backend.services.gemini.resources.search_resources import search_resources
from backend.services.resources.link_validation import validate_resources
from backend.services.resources.youtube_search import search_videos
from backend.utils.gemini.gemini_guard import run_gemini_background

logger = logging.getLogger(__name__)


async def run_resources_step(session, student_id) -> int:
    """Search, verify and store resources for each of the student's goals.
    Returns how many stuck. Returns 0 without calling Gemini when the app has
    no reading of this student."""
    contexts = await StudentContextRepository(session).list_valid(student_id)
    if not contexts:
        logger.info("Resources step: student %s has no context yet, skipping", student_id)
        return 0

    reading = f"{contexts[0].state} {contexts[0].metacognition}"
    student = await StudentRepository(session).get_by_id(student_id)
    language = Language.of(student.language if student else None)
    goals = await GoalRepository(session).list_by_student(student_id)

    total = 0
    for goal in goals:
        total += await _resources_for_goal(session, goal, reading, language)
    return total


async def _resources_for_goal(session, goal, reading: str, language: Language) -> int:
    repository = ResourceRepository(session)
    held = [resource.link for resource in await repository.list_by_goal(goal.id)]

    # The Gemini client is synchronous and this is a slow, grounded search, so
    # keep it off the event loop. Nobody is waiting on it, so it retries on the
    # background budget (backend/utils/gemini/gemini_retry.py).
    search = await run_gemini_background(
        search_resources, str(goal.id), goal.name, goal.description, reading, held, language
    )
    async with httpx.AsyncClient() as client:
        videos = await search_videos(client, str(goal.id), search.video_query, language)
        found = search.pages + videos
        logger.info("Found %d resources for goal %s", len(found), goal.id)
        verified = await validate_resources(found, client=client)

    # A page is only known by its address once its redirect is followed, and two
    # sources may land on one page: dedupe after validation, against the goal
    # and within the batch.
    already = await repository.existing_links(str(goal.id), [r.link for r in verified])
    fresh = []
    for resource in verified:
        if resource.link not in already:
            already.add(resource.link)
            fresh.append(resource)

    await repository.create_many(fresh)
    await session.commit()
    logger.info("Resources step: stored %d resources for goal %s", len(fresh), goal.id)
    return len(fresh)
