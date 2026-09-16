from app.models import User
from app.services.security import verify_password

from conftest import auth, signup


def test_signup_returns_a_bearer_token_that_works(client):
    token = signup(client)

    response = client.get("/meals", headers=auth(token))

    assert response.status_code == 200


def test_signup_stores_a_hash_not_the_password(client):
    signup(client, password="correct-horse")

    with client.session_factory() as db:
        user = db.query(User).filter(User.email == "ada@example.com").one()

    assert user.hashed_password != "correct-horse"
    assert verify_password("correct-horse", user.hashed_password)
    assert user.full_name == "Ada Lovelace"


def test_signup_rejects_an_email_that_is_already_registered(client):
    signup(client)

    response = client.post(
        "/auth/signup",
        json={
            "email": "ada@example.com",
            "password": "another-password",
            "first_name": "Ada",
            "last_name": "Again",
        },
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Email already registered"


def test_signup_rejects_passwords_shorter_than_eight_characters(client):
    response = client.post(
        "/auth/signup",
        json={
            "email": "ada@example.com",
            "password": "short",
            "first_name": "Ada",
            "last_name": "Lovelace",
        },
    )

    assert response.status_code == 422


def test_signup_rejects_an_invalid_email(client):
    response = client.post(
        "/auth/signup",
        json={
            "email": "not-an-email",
            "password": "correct-horse",
            "first_name": "Ada",
            "last_name": "Lovelace",
        },
    )

    assert response.status_code == 422


def test_login_with_the_right_password_returns_a_token(client):
    signup(client, password="correct-horse")

    response = client.post(
        "/auth/login",
        json={"email": "ada@example.com", "password": "correct-horse"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["token_type"] == "bearer"
    assert client.get("/meals", headers=auth(body["access_token"])).status_code == 200


def test_wrong_password_and_unknown_email_get_the_same_answer(client):
    # Identical responses mean the login form can't be used to discover
    # which email addresses have accounts.
    signup(client, password="correct-horse")

    wrong_password = client.post(
        "/auth/login",
        json={"email": "ada@example.com", "password": "wrong-horse"},
    )
    unknown_email = client.post(
        "/auth/login",
        json={"email": "nobody@example.com", "password": "correct-horse"},
    )

    assert wrong_password.status_code == unknown_email.status_code == 401
    assert wrong_password.json() == unknown_email.json()


def test_google_login_is_refused_when_it_is_not_configured(client):
    response = client.post("/auth/google", json={"token": "anything"})

    assert response.status_code == 400
    assert response.json()["detail"] == "Google login not configured"
