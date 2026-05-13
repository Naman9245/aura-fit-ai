from datetime import date
from typing import Literal

from pydantic import BaseModel, EmailStr, Field


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    first_name: str
    last_name: str


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class GoogleLogin(BaseModel):
    token: str


class OnboardingRequest(BaseModel):
    goal: Literal[
        "Gain Muscle",
        "Lose Fat",
        "Maintain Weight",
        "Body Recomposition",
        "Athletic Performance",
    ]
    workout_location: Literal["gym", "home"]
    experience_level: Literal["beginner", "intermediate", "advanced"]
    age: int
    weight_kg: float
    height_cm: float
    gender: Literal["male", "female", "other"]
    activity_level: Literal["sedentary", "lightly active", "active", "athlete"]
    target_weight: float | None = None
    target_physique: str | None = None
    diet_preference: str | None = None


class OnboardingMetrics(BaseModel):
    bmi: float
    bmr: float
    maintenance_calories: float
    calorie_goal: float
    protein_grams: float
    carbs_grams: float
    fats_grams: float
    water_liters: float
    daily_step_target: int


class OnboardingResponse(BaseModel):
    metrics: OnboardingMetrics


class MealScanResponse(BaseModel):
    items: list[dict]
    total_calories: float
    total_protein: float
    total_carbs: float
    total_fats: float


class ChatRequest(BaseModel):
    message: str
    context: dict | None = None


class ChatResponse(BaseModel):
    reply: str


class WorkoutPlanRequest(BaseModel):
    goal: str
    workout_location: str
    experience_level: str


class WorkoutPlanResponse(BaseModel):
    plan: list[dict]


class DailyProgressResponse(BaseModel):
    date: date
    calories_consumed: float
    calories_burned: float
    protein: float
    carbs: float
    fats: float
    water_ml: float
    steps: int
