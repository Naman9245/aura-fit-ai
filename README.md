# AURA FIT AI

[![backend tests](https://github.com/Naman9245/aura-fit-ai/actions/workflows/backend-tests.yml/badge.svg)](https://github.com/Naman9245/aura-fit-ai/actions/workflows/backend-tests.yml)

A fitness app with a Next.js front end and a FastAPI back end. Users sign up, answer an onboarding questionnaire, and get a personalised calorie goal and macro split. Meal logging is private to each user, and an optional Gemini integration powers a chat assistant and meal-photo analysis.

## Project status

**Working and covered by tests (45 pytest cases, run in GitHub Actions)**

- **Authentication** — sign-up and login with bcrypt-hashed passwords and HS256 JWTs. Missing, malformed, forged and expired tokens are rejected, and so are tokens for accounts that no longer exist. Wrong-password and unknown-email logins return identical responses, so the login form can't be used to find out who has an account.
- **Onboarding metrics** — BMI, BMR (Mifflin–St Jeor), maintenance calories with an activity multiplier, a goal-based calorie adjustment, and a macro split that adds back up to the calorie goal.
- **Meals** — validated input (no negative calories, no empty names); each user can only see their own meals.
- **AI endpoints** — require login, because they spend the Gemini quota. Without `GEMINI_API_KEY` they return an offline message or a sample result instead of failing.

**Not done yet**

- The frontend pages show sample data and aren't connected to the API yet. The client functions are in `frontend/src/lib/api.ts`.
- `/dashboard/daily` and `/workouts/plan` return fixed sample data.
- The Gemini integration uses the deprecated `google-generativeai` package and needs migrating to `google-genai` before it's switched on.

## Tech stack

| Layer | Technology |
|-------|------------|
| Frontend | Next.js 15, TypeScript, Tailwind CSS, Framer Motion, Recharts |
| Backend | FastAPI, SQLAlchemy 2, Pydantic v2, python-jose (JWT), passlib + bcrypt |
| Database | PostgreSQL in production (Supabase-compatible), SQLite for local development and tests |
| AI | Google Gemini (optional) |
| CI | GitHub Actions runs the backend test suite on every push and pull request |

## Project structure

```
backend/
├── app/
│   ├── main.py            # FastAPI app, CORS, router wiring
│   ├── core/config.py     # settings from environment; refuses the default JWT secret in production
│   ├── deps.py            # get_current_user: token → user, or 401
│   ├── routers/           # auth, onboarding, meals, workouts, dashboard, ai
│   ├── services/          # password hashing + JWTs, Gemini calls
│   └── utils/calculations.py  # BMI, BMR, calorie goal and macros
└── tests/                 # pytest suite against an in-memory SQLite database
frontend/
└── src/                   # Next.js app router pages, components, API client
```

## Run locally

### Backend

```bash
cd backend
cp .env.example .env        # set JWT_SECRET; DATABASE_URL can be sqlite:///./aura_fit_ai.db
python -m pip install -r requirements.txt
uvicorn app.main:app --reload
```

API docs are then at http://localhost:8000/docs.

### Frontend

```bash
cd frontend
cp .env.example .env.local
npm install
npm run dev
```

## Run the tests

```bash
cd backend
python -m pip install -r requirements-dev.txt
pytest
```

The tests use an in-memory SQLite database and need no API keys or network access.

## Configuration

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | Any SQLAlchemy URL — PostgreSQL in production, SQLite locally |
| `JWT_SECRET` | Signing key for access tokens; must be changed when `ENVIRONMENT=production` |
| `GEMINI_API_KEY` | Optional; enables the AI chat and meal-photo analysis |
| `GOOGLE_CLIENT_ID` | Optional; enables Google sign-in |
| `CORS_ORIGINS` | Comma-separated list of allowed frontend origins |
