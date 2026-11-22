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

**Next, in January 2027:** sign-in with Supabase Auth, food search and logging, water and steps, and today's dashboard. The live Supabase project doesn't exist yet; until it does, CI checks the migrations on plain Postgres.

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
├── lib/data/              the phone's database and what reads and writes it
├── lib/features/          onboarding, targets
├── test/                  unit, database and widget tests
└── tool/                  the Python parity export, screenshots
supabase/
├── migrations/            the schema, one SQL file per change
└── tests/                 security checks, and a shim to run them on plain Postgres
docs/adr/                  why the big decisions were made
backend/                   FastAPI, being retired
frontend/                  Next.js, becoming the landing page
```

## Run the app

```bash
cd app
flutter pub get
flutter run            # with an Android phone connected, or an emulator
```

To install on a phone without a cable session, build an APK and copy it over:

```bash
flutter build apk --release --split-per-abi
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Run the tests

```bash
cd app
flutter test                              # 102 tests, no network needed
flutter test tool/screenshots_test.dart   # draws every screen to build/screenshots/
```

The database checks run in CI on Postgres. On a Supabase project, apply the migrations in order and paste `supabase/tests/security_test.sql` into the SQL editor; it rolls itself back.

The old backend's tests still run until it is removed:

```bash
cd backend
python -m pip install -r requirements-dev.txt
pytest
```
