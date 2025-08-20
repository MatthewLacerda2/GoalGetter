import logging
from fastapi import FastAPI, Request
from backend.api.v1.endpoints import router as api_v1_router
from fastapi.middleware.cors import CORSMiddleware
from backend.core.logging_middleware import LoggingMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(name)s - %(message)s"
)

logger = logging.getLogger(__name__)

app = FastAPI(
    title="GoalGetter API",
    description="API for the GoalGetter app",
    version="1.0.0"
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

@app.get("/")
async def root(request: Request):
    return {"message": "Welcome to GoalGetter API"}

@app.get("/health")
async def health_check(request: Request):
    return {"status": "healthy"}