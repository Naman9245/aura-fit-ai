from datetime import date

from fastapi import APIRouter, Depends

from app.deps import get_current_user
from app.schemas import DailyProgressResponse

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/daily", response_model=DailyProgressResponse)
def daily_progress(user=Depends(get_current_user)):
    return DailyProgressResponse(
        date=date.today(),
        calories_consumed=1820,
        calories_burned=420,
        protein=128,
        carbs=210,
        fats=58,
        water_ml=2600,
        steps=8400,
    )
