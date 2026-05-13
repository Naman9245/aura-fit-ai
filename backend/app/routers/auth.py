from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
import httpx

from app.core.config import settings
from app.db import get_db
from app.models import User
from app.schemas import GoogleLogin, Token, UserCreate, UserLogin
from app.services.security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=Token)
def signup(payload: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        full_name=f"{payload.first_name} {payload.last_name}",
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token(user.email)
    return Token(access_token=token)


@router.post("/login", response_model=Token)
def login(payload: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == payload.email).first()
    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token(user.email)
    return Token(access_token=token)


@router.post("/google", response_model=Token)
async def google_login(payload: GoogleLogin, db: Session = Depends(get_db)):
    if not settings.google_client_id:
        raise HTTPException(
            status_code=400,
            detail="Google login not configured",
        )

    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://oauth2.googleapis.com/tokeninfo",
            params={"id_token": payload.token},
        )
    if response.status_code != 200:
        raise HTTPException(status_code=401, detail="Invalid Google token")

    data = response.json()
    if data.get("aud") != settings.google_client_id:
        raise HTTPException(status_code=401, detail="Invalid Google audience")

    email = data.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Email missing in token")

    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(
            email=email,
            hashed_password=hash_password(payload.token),
            full_name=data.get("name") or email,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    token = create_access_token(user.email)
    return Token(access_token=token)
