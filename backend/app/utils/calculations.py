from dataclasses import dataclass


@dataclass
class Metrics:
    bmi: float
    bmr: float
    maintenance_calories: float
    calorie_goal: float
    protein_grams: float
    carbs_grams: float
    fats_grams: float
    water_liters: float
    daily_step_target: int


def calculate_bmi(weight_kg: float, height_cm: float) -> float:
    height_m = height_cm / 100
    return round(weight_kg / (height_m**2), 2)


def calculate_bmr(weight_kg: float, height_cm: float, age: int, gender: str) -> float:
    base = 10 * weight_kg + 6.25 * height_cm - 5 * age
    if gender == "male":
        return base + 5
    if gender == "female":
        return base - 161
    return base - 78


def activity_multiplier(activity_level: str) -> float:
    multiplier = {
        "sedentary": 1.2,
        "lightly active": 1.375,
        "active": 1.55,
        "athlete": 1.725,
    }.get(activity_level)
    if multiplier is None:
        raise ValueError(f"Unsupported activity level: {activity_level}")
    return multiplier


def goal_adjustment(goal: str) -> int:
    adjustment = {
        "Gain Muscle": 300,
        "Lose Fat": -500,
        "Maintain Weight": 0,
        "Body Recomposition": -200,
        "Athletic Performance": 250,
    }.get(goal)
    if adjustment is None:
        raise ValueError(f"Unsupported goal: {goal}")
    return adjustment


def protein_multiplier(goal: str) -> float:
    multiplier = {
        "Gain Muscle": 2.2,
        "Lose Fat": 1.8,
        "Maintain Weight": 1.6,
        "Body Recomposition": 2.0,
        "Athletic Performance": 1.8,
    }.get(goal)
    if multiplier is None:
        raise ValueError(f"Unsupported goal: {goal}")
    return multiplier


def calculate_metrics(
    weight_kg: float,
    height_cm: float,
    age: int,
    gender: str,
    goal: str,
    activity_level: str,
) -> Metrics:
    bmi = calculate_bmi(weight_kg, height_cm)
    bmr = calculate_bmr(weight_kg, height_cm, age, gender)
    maintenance = bmr * activity_multiplier(activity_level)
    calorie_goal = maintenance + goal_adjustment(goal)

    protein_grams = protein_multiplier(goal) * weight_kg
    fats_grams = (calorie_goal * 0.25) / 9
    carbs_grams = (calorie_goal - (protein_grams * 4) - (fats_grams * 9)) / 4

    water_liters = (weight_kg * 35) / 1000
    if activity_level in {"active", "athlete"}:
        water_liters += 0.5

    daily_step_target = 8000
    if activity_level == "lightly active":
        daily_step_target = 9000
    elif activity_level == "active":
        daily_step_target = 11000
    elif activity_level == "athlete":
        daily_step_target = 13000

    return Metrics(
        bmi=round(bmi, 2),
        bmr=round(bmr, 2),
        maintenance_calories=round(maintenance, 2),
        calorie_goal=round(calorie_goal, 2),
        protein_grams=round(protein_grams, 1),
        carbs_grams=round(carbs_grams, 1),
        fats_grams=round(fats_grams, 1),
        water_liters=round(water_liters, 2),
        daily_step_target=daily_step_target,
    )
