from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import Meal
from app.schemas import MealCreate

router = APIRouter(prefix="/meals", tags=["meals"])


@router.post("")
def log_meal(payload: MealCreate, db: Session = Depends(get_db), user=Depends(get_current_user)):
    meal = Meal(user_id=user.id, **payload.model_dump())
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
