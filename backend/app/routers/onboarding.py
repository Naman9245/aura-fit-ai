from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import Goal
from app.schemas import OnboardingRequest, OnboardingResponse
from app.utils.calculations import calculate_metrics

router = APIRouter(prefix="/onboarding", tags=["onboarding"])


@router.post("/complete", response_model=OnboardingResponse)
def complete_onboarding(
    payload: OnboardingRequest,
    db: Session = Depends(get_db),
    user=Depends(get_current_user),
):
    metrics = calculate_metrics(
        weight_kg=payload.weight_kg,
        height_cm=payload.height_cm,
        age=payload.age,
        gender=payload.gender,
        goal=payload.goal,
        activity_level=payload.activity_level,
    )

    goal = Goal(
        user_id=user.id,
        goal_type=payload.goal,
        target_weight=payload.target_weight,
        target_physique=payload.target_physique,
        diet_preference=payload.diet_preference,
    )
    db.add(goal)
    db.commit()

    return OnboardingResponse(metrics=metrics.__dict__)
