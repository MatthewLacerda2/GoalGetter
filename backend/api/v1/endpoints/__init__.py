from fastapi import APIRouter
from backend.api.v1.endpoints import auth, goals, tutor

router = APIRouter()

router.include_router(auth.router, prefix="/auth", tags=["auth"])
router.include_router(goals.router, prefix="/goals", tags=["goals"])
router.include_router(tutor.router, prefix="/tutor", tags=["tutor"])
