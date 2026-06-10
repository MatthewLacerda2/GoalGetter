import logging

logger = logging.getLogger(__name__)

# These two jobs are kicked off (async, fire-and-forget) when a goal is created, so
# the response can return immediately while they run in the background — that's what
# the introduction screens buy time for. They also run periodically on their own
# schedule (resources: when the user's skill jumps or monthly, whichever first;
# lessons: a daily check that skips users who didn't do any lessons).
#
# TODO: implement both. For now they only log so the create flow is wired end-to-end.

def kickoff_resource_scraping(goal_id: str) -> None:
    """Scrape and embed study resources for the goal (the heavy, token-hungry job)."""
    logger.info("TODO: kickoff resource scraping for goal %s", goal_id)

def kickoff_lessons_generation(goal_id: str) -> None:
    """Generate the initial lesson bank for the goal."""
    logger.info("TODO: kickoff lessons generation for goal %s", goal_id)
