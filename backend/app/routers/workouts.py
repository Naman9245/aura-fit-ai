from fastapi import APIRouter, Depends

from app.deps import get_current_user
from app.schemas import WorkoutPlanRequest, WorkoutPlanResponse

router = APIRouter(prefix="/workouts", tags=["workouts"])


@router.post("/plan", response_model=WorkoutPlanResponse)
def generate_plan(
    payload: WorkoutPlanRequest,
    user=Depends(get_current_user),
):
    plan = [
        {
            "name": "Barbell squat",
            "sets": 4,
            "reps": 8,
            "rest": "90s",
            "difficulty": payload.experience_level,
            "calories": 110,
        },
        {
            "name": "Incline press",
            "sets": 3,
            "reps": 10,
            "rest": "75s",
            "difficulty": payload.experience_level,
            "calories": 90,
        },
        {
            "name": "Cable row",
            "sets": 3,
            "reps": 12,
            "rest": "60s",
            "difficulty": payload.experience_level,
            "calories": 80,
        },
    ]
    return WorkoutPlanResponse(plan=plan)
