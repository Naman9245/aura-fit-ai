from datetime import datetime, timedelta, timezone

import pytest
from jose import jwt

from app.models import Goal, User

from conftest import auth, signup

ONBOARDING = {
    "goal": "Lose Fat",
    "workout_location": "gym",
    "experience_level": "beginner",
    "age": 25,
    "weight_kg": 70,
    "height_cm": 175,
    "gender": "male",
    "activity_level": "active",
}
WORKOUT_REQUEST = {
    "goal": "Lose Fat",
    "workout_location": "gym",
    "experience_level": "beginner",
}
MEAL = {"name": "Oats", "calories": 350, "protein": 12, "carbs": 60, "fats": 6}

PROTECTED = [
    ("get", "/dashboard/daily", {}),
    ("get", "/meals", {}),
    ("post", "/meals", {"json": MEAL}),
    ("post", "/workouts/plan", {"json": WORKOUT_REQUEST}),
    ("post", "/onboarding/complete", {"json": ONBOARDING}),
    ("post", "/ai/chat", {"json": {"message": "hi"}}),
    ("post", "/ai/meal-scan", {"files": {"image": ("meal.jpg", b"not-really-a-jpeg", "image/jpeg")}}),
]


def token_for(email, secret="test-secret", expires_in=timedelta(hours=1)):
    return jwt.encode(
        {"sub": email, "exp": datetime.now(timezone.utc) + expires_in},
        secret,
        algorithm="HS256",
    )


@pytest.mark.parametrize("method,path,kwargs", PROTECTED)
def test_every_user_endpoint_requires_a_token(client, method, path, kwargs):
    response = getattr(client, method)(path, **kwargs)

    assert response.status_code == 401


@pytest.mark.parametrize("method,path,kwargs", PROTECTED)
def test_every_user_endpoint_accepts_a_valid_token(client, method, path, kwargs):
    token = signup(client)

    response = getattr(client, method)(path, headers=auth(token), **kwargs)

    assert response.status_code == 200, response.text


def test_a_malformed_token_is_rejected(client):
    response = client.get("/meals", headers=auth("not.a.jwt"))

    assert response.status_code == 401


def test_a_token_signed_with_a_different_secret_is_rejected(client):
    signup(client)
    forged = token_for("ada@example.com", secret="attacker-secret")

    response = client.get("/meals", headers=auth(forged))

    assert response.status_code == 401


def test_an_expired_token_is_rejected(client):
    signup(client)
    expired = token_for("ada@example.com", expires_in=timedelta(minutes=-1))

    response = client.get("/meals", headers=auth(expired))

    assert response.status_code == 401


def test_a_valid_token_for_a_deleted_account_is_rejected(client):
    token = signup(client)
    with client.session_factory() as db:
        db.query(User).delete()
        db.commit()

    response = client.get("/meals", headers=auth(token))

    assert response.status_code == 401


def test_users_only_ever_see_their_own_meals(client):
    ada = signup(client, email="ada@example.com")
    grace = signup(client, email="grace@example.com")

    client.post("/meals", headers=auth(ada), json=MEAL)
    client.post("/meals", headers=auth(grace), json={**MEAL, "name": "Toast"})

    ada_meals = client.get("/meals", headers=auth(ada)).json()
    grace_meals = client.get("/meals", headers=auth(grace)).json()

    assert [meal["name"] for meal in ada_meals] == ["Oats"]
    assert [meal["name"] for meal in grace_meals] == ["Toast"]


@pytest.mark.parametrize(
    "bad_meal",
    [
        {**MEAL, "calories": -100},
        {**MEAL, "protein": "lots"},
        {"name": ""},
    ],
)
def test_invalid_meals_are_rejected_instead_of_crashing(client, bad_meal):
    token = signup(client)

    response = client.post("/meals", headers=auth(token), json=bad_meal)

    assert response.status_code == 422


def test_onboarding_returns_metrics_and_saves_the_goal(client):
    token = signup(client)

    response = client.post("/onboarding/complete", headers=auth(token), json=ONBOARDING)

    assert response.status_code == 200
    metrics = response.json()["metrics"]
    assert metrics["bmi"] == 22.86
    assert metrics["daily_step_target"] == 11000
    with client.session_factory() as db:
        goals = db.query(Goal).all()
    assert [goal.goal_type for goal in goals] == ["Lose Fat"]


def test_ai_endpoints_fall_back_safely_without_an_api_key(client):
    token = signup(client)

    chat = client.post("/ai/chat", headers=auth(token), json={"message": "hi"})

    assert chat.status_code == 200
    assert "offline" in chat.json()["reply"]
