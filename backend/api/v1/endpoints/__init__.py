from fastapi import APIRouter
from backend.api.v1.endpoints import auth

router = APIRouter()

router.include_router(auth.router, prefix="/auth", tags=["auth"])