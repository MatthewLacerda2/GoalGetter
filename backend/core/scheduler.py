import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from backend.services.mastery_evaluation_job import run_mastery_evaluation_job
from backend.services.chat_context_job import run_chat_context_job
from backend.services.lesson_context_job import run_lesson_context_job

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


def setup_scheduler_jobs() -> None:

    scheduler.add_job(
        run_lesson_context_job,
        trigger=CronTrigger(hour=2, minute=0),
        id="lesson_context_job",
        name="Daily Lesson Context Generation Job",
        replace_existing=True,
        max_instances=1
    )
    
    scheduler.add_job(
        run_chat_context_job,
        trigger=CronTrigger(hour=3, minute=0),
        id="chat_context_job",
        name="Daily Chat Context Generation Job",
        replace_existing=True,
        max_instances=1
    )
    
    scheduler.add_job(
        run_mastery_evaluation_job,
        trigger=CronTrigger(hour=5, minute=0),
        id="mastery_evaluation_job",
        name="Daily Mastery Evaluation Job",
        replace_existing=True,
        max_instances=1  # Ensure only one instance runs at a time
    )

def start_scheduler() -> None:
    """Start the scheduler."""
    logger.info("Starting APScheduler")
    scheduler.start()
    logger.info("Scheduler started")


def stop_scheduler() -> None:
    """Stop the scheduler."""
    scheduler.shutdown()
