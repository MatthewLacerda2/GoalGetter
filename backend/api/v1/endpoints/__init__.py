from fastapi import APIRouter
from backend.api.v1.endpoints import auth, goals, lessons

router = APIRouter()

router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(goals.router, prefix="/goals", tags=["goals"])
router.include_router(lessons.router, prefix="/goals", tags=["lessons"])