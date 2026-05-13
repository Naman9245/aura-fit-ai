# AURA FIT AI

A full-stack futuristic AI fitness operating system with cinematic onboarding, glassmorphism UI, and AI-driven insights.

## Tech Stack

**Frontend**
- Next.js 15 + TypeScript + Tailwind CSS
- Framer Motion, Recharts, Lucide Icons
- shadcn/ui-inspired components

**Backend**
- FastAPI (Python)
- PostgreSQL (Supabase-compatible)
- JWT authentication
- Gemini Vision integration (optional)

## Project Structure

```
frontend/   # Next.js application
backend/    # FastAPI application
```

## Environment Setup

### Frontend

```
cp frontend/.env.example frontend/.env.local
```

### Backend

```
cp backend/.env.example backend/.env
```

## Run Locally

### Frontend

```
cd frontend
npm install
npm run dev
```

### Backend

```
cd backend
python -m pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Notes

- Configure `GEMINI_API_KEY` for Gemini Vision food analysis.
- Configure `GOOGLE_CLIENT_ID` to enable Google OAuth login.
- Update `DATABASE_URL` to your Supabase PostgreSQL connection string.
