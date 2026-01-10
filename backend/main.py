import logging
import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from backend.api.v1.endpoints import router as api_v1_router
from backend.core.logging_middleware import LoggingMiddleware
from backend.services.mastery_evaluation_job import run_mastery_evaluation_job
from backend.llms import get_llms_txt
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from fastapi.responses import PlainTextResponse

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(name)s - %(message)s"
)

logger = logging.getLogger(__name__)

# Global scheduler instance
scheduler = AsyncIOScheduler()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    FastAPI lifespan context manager to start and stop the scheduler.
    """
    # Startup: Start the scheduler and add jobs
    logger.info("Starting APScheduler")
    scheduler.start()
    
    # Schedule the mastery evaluation job to run daily at 2:00 AM
    scheduler.add_job(
        run_mastery_evaluation_job,
        trigger=CronTrigger(hour=2, minute=0),
        id="mastery_evaluation_job",
        name="Daily Mastery Evaluation Job",
        replace_existing=True,
        max_instances=1  # Ensure only one instance runs at a time
    )
    logger.info("Scheduled mastery evaluation job to run daily at 2:00 AM")
    
    yield
    
    # Shutdown: Stop the scheduler
    logger.info("Shutting down APScheduler")
    scheduler.shutdown()

app = FastAPI(
    title="GoalGetter API",
    description="API for the GoalGetter app",
    version="1.0.0",
    docs_url="/api/v1/docs",  # Move docs to /api/v1/docs
    redoc_url="/api/v1/redoc",  # Move redoc to /api/v1/redoc
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

app.add_middleware(LoggingMiddleware)
app.include_router(api_v1_router, prefix="/api/v1")

@app.get("/api/v1/check")
async def root(request: Request):
    return {"message": "Welcome to GoalGetter API"}

SECURITY_TXT = "Contact: matheus.l1996@gmail.com\n"

@app.get("/security.txt", response_class=PlainTextResponse)
async def security_txt_fallback():
    return SECURITY_TXT

@app.get("/llms.txt", response_class=PlainTextResponse)
async def llms_txt():
    return get_llms_txt()
