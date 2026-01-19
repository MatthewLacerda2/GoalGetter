import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from backend.services.mastery_evaluation_job import run_mastery_evaluation_job
from backend.services.chat_context_job import run_chat_context_job
from backend.services.lesson_context_job import run_lesson_context_job

logger = logging.getLogger(__name__)

# Global scheduler instance
scheduler = AsyncIOScheduler()


def setup_scheduler_jobs() -> None:
    """
    Configure all scheduled jobs for the application.
    This function should be called once during application startup.
    """
    logger.info("Setting up scheduled jobs")
    
    # Schedule the lesson context generation job to run daily at 2:00 AM
    scheduler.add_job(
        run_lesson_context_job,
        trigger=CronTrigger(hour=2, minute=0),
        id="lesson_context_job",
        name="Daily Lesson Context Generation Job",
        replace_existing=True,
        max_instances=1
    )
    logger.info("Scheduled lesson context generation job to run daily at 2:00 AM")
    
    # Schedule the chat context generation job to run daily at 3:00 AM
    scheduler.add_job(
        run_chat_context_job,
        trigger=CronTrigger(hour=3, minute=0),
        id="chat_context_job",
        name="Daily Chat Context Generation Job",
        replace_existing=True,
        max_instances=1
    )
    logger.info("Scheduled chat context generation job to run daily at 3:00 AM")
    
    # Schedule the mastery evaluation job to run daily at 5:00 AM
    scheduler.add_job(
        run_mastery_evaluation_job,
        trigger=CronTrigger(hour=5, minute=0),
        id="mastery_evaluation_job",
        name="Daily Mastery Evaluation Job",
        replace_existing=True,
        max_instances=1  # Ensure only one instance runs at a time
    )
    logger.info("Scheduled mastery evaluation job to run daily at 5:00 AM")

def start_scheduler() -> None:
    """Start the scheduler."""
    logger.info("Starting APScheduler")
    scheduler.start()


def stop_scheduler() -> None:
    """Stop the scheduler."""
    logger.info("Shutting down APScheduler")
    scheduler.shutdown()
