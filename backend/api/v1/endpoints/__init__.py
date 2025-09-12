from fastapi import APIRouter
from backend.api.v1.endpoints import objective, onboarding, achievements, auth, chat, resources, streak, activities, assessments, learn_info
from backend.core.rate_limiter import limiter

router = APIRouter()

router.dependency_overrides = {
    "rate_limit": limiter.limit("60/minute")
}

router.include_router(onboarding.router, prefix="/onboarding", tags=["onboarding"])
router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(achievements.router, prefix="/achievements", tags=["achievements"])
router.include_router(chat.router, prefix="/chat", tags=["chat"])
router.include_router(resources.router, prefix="/resources", tags=["resources"])
router.include_router(streak.router, prefix="/streak", tags=["streak"])
router.include_router(objective.router, prefix="/objective", tags=["objective"])
#router.include_router(activities.router, prefix="/activities", tags=["activities"])
#router.include_router(assessments.router, prefix="/assessments", tags=["assessments"])
#router.include_router(learn_info.router, prefix="/learn_info", tags=["learn_info"])