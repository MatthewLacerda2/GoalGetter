import logging

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from backend.api.v1.endpoints import router as api_v1_router
from backend.core.config import settings
from backend.core.cors import PRODUCTION_ORIGINS, cors_origin_regex
from backend.core.logging_middleware import LoggingMiddleware
from backend.core.rate_limiter import limiter
from backend.llms import get_llms_txt

# App-wide log format. Nothing logs from this module itself; the middleware and
# the services take their loggers from here.
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(name)s - %(message)s"
)


# There is no lifespan here on purpose (#157). Starting the app used to drop the
# public schema and rebuild it from the models, which was free while the tables
# were still moving and is fatal with a real student in the database. The schema
# is owned by backend/alembic/versions/ now, applied by the `migrate` service
# before this one starts (docker-compose.yml). By hand: `make migrate`.
app = FastAPI(
    title="GoalGetter API",
    description="API for the GoalGetter app",
    version="1.0.0",
    openapi_url="/api/v1/openapi.json",
    docs_url="/api/v1/docs",  # Move docs to /api/v1/docs
    redoc_url="/api/v1/redoc",  # Move redoc to /api/v1/redoc
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=PRODUCTION_ORIGINS,
    allow_origin_regex=cors_origin_regex(settings.DEV_LOGIN),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)

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
