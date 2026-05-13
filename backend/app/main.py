from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.db import Base, engine
from app.routers import ai, auth, dashboard, meals, onboarding, workouts

app = FastAPI(title=settings.app_name)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"]
)

Base.metadata.create_all(bind=engine)

app.include_router(auth.router)
app.include_router(onboarding.router)
app.include_router(ai.router)
app.include_router(meals.router)
app.include_router(workouts.router)
app.include_router(dashboard.router)


@app.get("/")
def root():
    return {"status": "AURA FIT AI backend online"}
