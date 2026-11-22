# ADR-001: Build the app in Flutter on Supabase

- **Date:** 22 November 2026
- **Status:** Accepted

## Context

AURA FIT AI began as a Next.js website with a FastAPI backend. The website's screens showed sample data and weren't connected to the API, and nothing was deployed.

The product is a phone app: Android first, with a Play Store launch planned for May 2027. Logging has to work with no network (PRD requirement N4), and the backend has to cope with 1 lakh daily users. One developer builds it, alongside college.

Penny, the same developer's money app, already runs on Flutter and Supabase: offline storage, sync between phones, Google sign-in, AI calls with daily limits and account deletion.

## Decision

- The app is built in **Flutter**, Android first and iOS later.
- **Drift** (SQLite) on the phone is the working copy. Screens read and write only there, and a sync engine copies changes to the server.
- **Supabase** is the server: Postgres with row-level security on every user table, Supabase Auth for sign-in, and Edge Functions for anything that needs a secret key, like AI.
- The calorie maths runs on the phone, in Dart.

## Options considered

| Option | For | Against |
|--------|-----|---------|
| Capacitor around the Next.js site | Reuses the website's screens | The screens were mock-ups, so there was little to reuse; offline storage and native features are harder |
| A web app installed from the browser (PWA) | Fastest to ship | No Health Connect later, so steps and weight would always be typed in |
| Flutter with the FastAPI backend | Keeps the Python code | A second service to deploy, secure and scale; it was never deployed, and its AI and Google sign-in calls blocked the server while they waited |
| **Flutter on Supabase** | A stack already proven on Penny; the database itself keeps each person's rows private; no server to run | Depends on Supabase |

## Consequences

- The FastAPI backend is retired once the January 2027 milestone works. Its calorie maths and its 13 calculation tests moved to Dart, and a recorded set of its answers keeps the Dart honest. Its AI prompts move to Edge Functions.
- About 10 screens are rebuilt in Flutter. The Next.js site stays only as the landing page, for search and sharing.
- iOS builds need a Mac or a cloud build service, so iOS comes after Android.
- To limit the dependence on Supabase, the schema is plain Postgres with SQL migrations, and Edge Functions are small TypeScript files; both can move to another host.
- Every user table carries sync columns and row-level security from the start, and CI checks the security rules on Postgres.
