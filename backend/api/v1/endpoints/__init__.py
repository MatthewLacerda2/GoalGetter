from fastapi import APIRouter
from backend.api.v1.endpoints import roadmap, achievements, auth, chat, resources, task, streak
from backend.core.rate_limiter import limiter

router = APIRouter()

router.dependency_overrides = {
    "rate_limit": limiter.limit("60/minute")
}

router.include_router(roadmap.router, prefix="/roadmap", tags=["roadmap"])
router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(achievements.router, prefix="/achievements", tags=["achievements"])
router.include_router(chat.router, prefix="/chat", tags=["chat"])
router.include_router(resources.router, prefix="/resources", tags=["resources"])
router.include_router(streak.router, prefix="/streak", tags=["streak"])
router.include_router(task.router, prefix="/task", tags=["task"])