from fastapi import FastAPI
from backend.api.v1.endpoints import roadmap

app = FastAPI(title="GoalGetter API", version="1.0.0")

# Include the roadmap router
app.include_router(roadmap.router, prefix="/api/v1")
