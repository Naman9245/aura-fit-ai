"""Records what the old Python maths returns for 30 sample profiles.

The Flutter app's calorie maths is a port of backend/app/utils/calculations.py.
This writes the Python's answers to test/fixtures/python_targets.json, and
test/services/python_parity_test.dart checks the Dart gives the same numbers,
apart from the cases where the new calorie floor deliberately changes them.

Run it from the repo root while backend/ still exists:

    python app/tool/export_python_targets.py

The FastAPI backend is retired in January 2027. The JSON file stays as the
record of what it calculated.
"""

import json
import sys
from dataclasses import asdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "app" / "test" / "fixtures" / "python_targets.json"

sys.path.insert(0, str(REPO / "backend"))
from app.utils.calculations import calculate_metrics  # noqa: E402

GOALS = ["Gain Muscle", "Lose Fat", "Maintain Weight", "Body Recomposition", "Athletic Performance"]
ACTIVITY = ["sedentary", "lightly active", "active", "athlete"]

# (weight kg, height cm, age, gender, goal, activity level, why it's here)
PROFILES = [
    # The profile the Python tests use, with every goal.
    *[(70, 175, 25, "male", goal, "active", "the Python tests' profile") for goal in GOALS],
    # The 889 kcal case: the floor raises it to 1,200.
    (50, 155, 30, "female", "Lose Fat", "sedentary", "floor, female"),
    (50, 160, 60, "male", "Lose Fat", "sedentary", "floor, male"),
    (48, 150, 45, "other", "Lose Fat", "sedentary", "floor, sex not given"),
    (45, 150, 70, "female", "Body Recomposition", "lightly active", "floor, older"),
    # A maintenance of exactly 2303.125 kcal: Python rounds it to 2303.12,
    # and rounding the tie away from zero would give 2303.13.
    (70, 176, 26, "male", "Maintain Weight", "lightly active", "rounding tie"),
    (70, 176, 26, "male", "Gain Muscle", "lightly active", "rounding tie"),
    # Decimal weights and heights, as people type them.
    (55.5, 160.5, 22, "female", "Maintain Weight", "lightly active", "decimals"),
    (62.3, 168.2, 28, "female", "Lose Fat", "active", "decimals"),
    (70.4, 172.7, 33, "male", "Body Recomposition", "athlete", "decimals"),
    (92.3, 181.4, 41, "male", "Lose Fat", "lightly active", "decimals"),
    (78.9, 177.8, 19, "other", "Athletic Performance", "active", "decimals, sex not given"),
    # Ages, sizes and activity levels across the range.
    (58, 158, 18, "female", "Gain Muscle", "sedentary", "youngest allowed"),
    (65, 162, 35, "female", "Athletic Performance", "athlete", "athlete"),
    (85, 183, 42, "male", "Maintain Weight", "sedentary", "sedentary"),
    (100, 190, 47, "male", "Lose Fat", "active", "heavy"),
    (120, 185, 29, "male", "Gain Muscle", "athlete", "heaviest"),
    (72, 165, 55, "female", "Lose Fat", "lightly active", "older"),
    (68, 170, 63, "other", "Maintain Weight", "lightly active", "older, sex not given"),
    (60, 152, 90, "female", "Maintain Weight", "sedentary", "very old"),
    (75, 178, 100, "male", "Lose Fat", "sedentary", "oldest allowed"),
    (52, 148, 24, "female", "Body Recomposition", "active", "short"),
    (88, 201, 26, "male", "Athletic Performance", "athlete", "tall"),
    (66.6, 171.1, 31, "male", "Body Recomposition", "sedentary", "repeating decimals"),
    (80, 175, 38, "female", "Gain Muscle", "active", "gaining, female"),
    # Python gives negative carbs here; the carb rule cuts fat instead.
    (150, 120, 100, "female", "Lose Fat", "sedentary", "carbs below zero"),
]


def main():
    cases = []
    for weight, height, age, gender, goal, activity, why in PROFILES:
        metrics = calculate_metrics(
            weight_kg=weight,
            height_cm=height,
            age=age,
            gender=gender,
            goal=goal,
            activity_level=activity,
        )
        cases.append(
            {
                "why": why,
                "input": {
                    "weight_kg": weight,
                    "height_cm": height,
                    "age": age,
                    "gender": gender,
                    "goal": goal,
                    "activity_level": activity,
                },
                "output": asdict(metrics),
            }
        )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(cases, indent=2) + "\n", encoding="utf-8")
    print(f"wrote {len(cases)} cases to {OUT.relative_to(REPO)}")


if __name__ == "__main__":
    main()
