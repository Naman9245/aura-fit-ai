import os

# Settings are read when app modules are first imported, so the test values
# must be in place before that. Environment variables beat a local .env file.
os.environ["ENVIRONMENT"] = "test"
os.environ["DATABASE_URL"] = "sqlite://"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["GEMINI_API_KEY"] = ""
os.environ["GOOGLE_CLIENT_ID"] = ""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import Base, get_db
from app.main import app


@pytest.fixture
def client():
    # A fresh in-memory database per test. StaticPool keeps every session on the
    # same connection, otherwise each one would see its own empty database.
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)

    def override_get_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        test_client.session_factory = TestingSession
        yield test_client
    app.dependency_overrides.clear()
    engine.dispose()


def signup(client, email="ada@example.com", password="correct-horse"):
    response = client.post(
        "/auth/signup",
        json={
            "email": email,
            "password": password,
            "first_name": "Ada",
            "last_name": "Lovelace",
        },
    )
    assert response.status_code == 200, response.text
    return response.json()["access_token"]


def auth(token):
    return {"Authorization": f"Bearer {token}"}
