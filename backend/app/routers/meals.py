from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import Meal

router = APIRouter(prefix="/meals", tags=["meals"])


@router.post("")
def log_meal(payload: dict, db: Session = Depends(get_db), user=Depends(get_current_user)):
    meal = Meal(
        user_id=user.id,
        name=payload.get("name", "Meal"),
        calories=payload.get("calories", 0),
        protein=payload.get("protein", 0),
        carbs=payload.get("carbs", 0),
        fats=payload.get("fats", 0),
    )
    db.add(meal)
    db.commit()
    db.refresh(meal)
    return {"id": meal.id}


@router.get("")
def list_meals(db: Session = Depends(get_db), user=Depends(get_current_user)):
    meals = db.query(Meal).filter(Meal.user_id == user.id).all()
    return [
        {
            "id": meal.id,
            "name": meal.name,
            "calories": meal.calories,
            "protein": meal.protein,
            "carbs": meal.carbs,
            "fats": meal.fats,
        }
        for meal in meals
    ]
