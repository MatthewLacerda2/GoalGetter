from fastapi import APIRouter
from backend.api.v1.endpoints import roadmap, test
from backend.core.rate_limiter import limiter

router = APIRouter()

router.dependency_overrides = {
    "rate_limit": limiter.limit("60/minute")
}

router.include_router(roadmap.router, prefix="/roadmap", tags=["roadmap"])
router.include_router(test.router, prefix="/test", tags=["test"])   