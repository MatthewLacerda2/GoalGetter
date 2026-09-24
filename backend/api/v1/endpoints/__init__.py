from fastapi import APIRouter
from backend.api.v1.endpoints import auth, goals, home, lessons, me, resources, tutor

router = APIRouter()

router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(goals.router, prefix="/goals", tags=["goals"])
router.include_router(home.router, prefix="/home", tags=["home"])
router.include_router(lessons.router, prefix="/goals", tags=["lessons"])
router.include_router(me.router, prefix="/me", tags=["me"])
router.include_router(resources.router, prefix="/resources", tags=["resources"])
router.include_router(tutor.router, prefix="/tutor", tags=["tutor"])
