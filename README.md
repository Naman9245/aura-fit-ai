# AURA FIT AI

[![app tests](https://github.com/Naman9245/aura-fit-ai/actions/workflows/app-tests.yml/badge.svg)](https://github.com/Naman9245/aura-fit-ai/actions/workflows/app-tests.yml)
[![backend tests](https://github.com/Naman9245/aura-fit-ai/actions/workflows/backend-tests.yml/badge.svg)](https://github.com/Naman9245/aura-fit-ai/actions/workflows/backend-tests.yml)

A fitness app for Indians who cook at home and train at a gym or at home: log a day of meals in under a minute, and get daily targets that are personal and safe. It is being built as an Android app in Flutter on Supabase ([why](docs/adr/001-flutter-and-supabase.md)), with the first Play Store release planned for May 2027.

## Project status

**Foundation (the December 2026 milestone): done**

- **The Flutter app** in `app/`. Onboarding asks for the goal, birth date, sex, height and weight, activity level, diet and training, then shows daily targets for calories, protein, carbs, fat, water and steps, and a "How we calculated this" screen. Everything is saved on the phone, so it works with no network.
- **Calorie maths in Dart**, ported from the Python backend with three fixes: calories never go below 1,200 kcal for women or 1,500 kcal for men, carbs never go negative, and age comes from the birth date. It gives exactly the Python's numbers on 30 recorded profiles, apart from where the fixes deliberately change them.
- **The Supabase schema** in `supabase/migrations/`: profiles, goals, weigh-ins, meal entries and health samples with row-level security and sync columns, a shared food catalogue, and daily AI limits. `supabase/tests/security_test.sql` checks the rules.
- **CI** runs the formatter, the analyzer and 102 app tests, and applies the migrations to Postgres and runs the security checks.

**January 2027 milestone, "Core loop works end to end": in progress**

- **Sign-in and sync** (the first of four pull requests). Sign in with Google, or with an email and password confirmed by a 6-digit code. The plan made during onboarding moves into the account, and every change goes up to Supabase a few seconds after it's made, or within a minute of the network coming back while the app is open. Another phone's changes come down, the newer edit of a row wins, and the app never waits on the network.
- **Next:** food search and typed logging, then repeat and favourites, water and steps, and today's dashboard.

The Supabase project `aura-fit` (Mumbai, free plan) has every migration applied and passes the security and sync checks; CI also checks them on plain Postgres.

**Being retired:** `backend/` (FastAPI, 45 tests) goes once the January milestone works; its maths and tests have moved to Dart. `frontend/` (Next.js) shows sample data and isn't connected to anything; it will become the landing page.

## Tech stack

| Layer | Technology |
|-------|------------|
| App | Flutter, Android first; Riverpod, go_router |
| On the phone | Drift (SQLite): the app reads and writes here, so it works offline |
| Server | Supabase: Postgres with row-level security, Auth, Edge Functions for AI |
| Website | Next.js, as the landing page |
| CI | GitHub Actions |

## Project structure

```
app/                       Flutter app
├── lib/services/targets.dart   the calorie maths, formula v1
├── lib/data/              the phone's database, sign-in, and sync with the account
├── lib/features/          onboarding, targets, signing in
├── test/                  unit, database and widget tests
└── tool/                  the Python parity export, screenshots
supabase/
├── migrations/            the schema, one SQL file per change
└── tests/                 security and sync checks, and a shim to run them on plain Postgres
docs/adr/                  why the big decisions were made
backend/                   FastAPI, being retired
frontend/                  Next.js, becoming the landing page
```

## Run the app

The app finds its server through `app/env/supabase.json`, which stays out of git. Copy `app/env/supabase.example.json` there and fill in the project's URL, its publishable key and Google's Web client ID. All three are public by design; row-level security guards everything behind them. A build without the file runs, but can't sign in, and says so.

```bash
cd app
flutter pub get
flutter run --dart-define-from-file=env/supabase.json   # with an Android phone connected, or an emulator
```

To install on a phone without a cable session, build an APK and copy it over:

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=env/supabase.json
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Run the tests

```bash
cd app
flutter test                              # 141 tests, no network needed
flutter test tool/screenshots_test.dart   # draws every screen to build/screenshots/
```

The database checks run in CI on Postgres. On a Supabase project, apply the migrations in order and paste `supabase/tests/security_test.sql`, then `supabase/tests/sync_test.sql`, into the SQL editor; each rolls itself back.

The old backend's tests still run until it is removed:

```bash
cd backend
python -m pip install -r requirements-dev.txt
pytest
```
