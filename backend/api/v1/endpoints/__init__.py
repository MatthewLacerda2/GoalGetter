from fastapi import APIRouter
from backend.api.v1.endpoints import roadmap
from backend.core.rate_limiter import limiter

router = APIRouter()

router.dependency_overrides = {
    "rate_limit": limiter.limit("60/minute")
}

router.include_router(roadmap.router, prefix="/roadmap", tags=["roadmap"])