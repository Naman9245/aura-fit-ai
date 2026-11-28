# AURA FIT AI

[![app tests](https://github.com/Naman9245/aura-fit-ai/actions/workflows/app-tests.yml/badge.svg)](https://github.com/Naman9245/aura-fit-ai/actions/workflows/app-tests.yml)

A fitness app for Indians who cook at home, eat at a mess or a dhaba, and train at a gym or at home. It logs a day of Indian meals in under a minute, sets daily targets that are personal and safe, builds a weekly workout plan for the gym, dumbbells or no equipment, and has a mascot, Josh the bear, who cheers you on.

It's an Android app in Flutter on Supabase ([why](docs/adr/001-flutter-and-supabase.md)). Everything works offline on the phone; an account backs it up and syncs it. The first Play Store release is planned for May 2027.

**Where it stands (28 November 2026):** the PRD's P0 launch scope and the "Your trainer" milestone are built and merged, with 216 app tests passing, and the live Supabase project is up to date. Next is getting it to testers: see [What's left](#whats-left).

## Contents

- [Features](#features)
- [Architecture](#architecture)
- [Repository layout](#repository-layout)
- [Run, test and build](#run-test-and-build)
- [Rules for changing things](#rules-for-changing-things)
- [What's left](#whats-left)

## Features

### Getting started

- **Josh's intro.** Five screens: Josh says hello, shows what the app does (your plan, coaching every set, food for training) and ends with "We'll do this together". It can be replayed from the account sheet.
- **Onboarding.** Goal (lose fat, gain muscle, recomposition, stay healthy), birth date, sex, height (cm or feet and inches) and weight, activity level and diet.
- **Daily targets.** Calories, protein, carbs, fat, water and steps. **How we calculated this** shows the working step by step, with the sources (Mifflin–St Jeor; ICMR-NIN).
  - Calories never go below the safe minimum: 1,200 kcal for women, 1,500 kcal for men.
  - Formula v2 uses adjusted weight above BMI 30, and caps deficits by maintenance.
  - Each goal keeps the formula version it was made with, so old targets never change underneath you.
- **An account is optional.** The app works fully without one: everything stays on the phone. Signing in (Google, or email with a 6-digit code) backs everything up and syncs it across phones. Only typing a meal for AI to read needs an account.

### Today

- **Josh's card:**
  - Your streak and a greeting.
  - A line that always names the next goal to go for: "3 of 5 done. 2,600 steps to go. So close!"
  - When a day needs a second look, like well over target or very low in the evening, the card turns calm yellow (never red) and says so kindly.
  - Josh's mood follows the day: happy, fired up, proud, calm or sleepy.
- **Today's goals:**
  - The goals: calories on target, protein, water, steps, and the day's workout. Rest days count as done.
  - Rings fill as each goal gets closer, then turn into ticks.
  - Calories only count as done near the target and never below the safe minimum, so eating too little is never a goal met.
- **Calories card:**
  - A ring with what's left, plus carbs and fat.
  - A 7-day average.
  - **Log food**.
- **Protein and water cards**, with **+250 ml** water in one tap and a sheet of container sizes.
- **Steps and weight** on scroll wheels, so no keyboard is needed.
- **Protein ideas** matched to your diet (veg, egg, non-veg, vegan). Tapping one searches it.
- **Yesterday / Today** switch, shared with the Food tab.

### Food

- **Pick the meal.** Breakfast, lunch, snack or dinner; it defaults by the time of day.
- **"What did you eat?"**
  - Type it in English or Hinglish, or use the keyboard's mic.
  - AI reads it, and the food list supplies the numbers wherever a dish matches.
  - You check and adjust everything before it's saved.
  - Offline, or past the daily limit, it falls back calmly to search and quick add.
- **Search 527 Indian foods**, offline and in under 50 ms:
  - What's in the list: raw staples from USDA, home and mess dishes worked out by recipe with their assumptions shown, packaged staples from labels, and fast food, Indo-Chinese, sweets and drinks.
  - Spelling-tolerant: "parantha", "gobhi", "daal", "panner", "chaval" and "makke di roti" all work.
  - Typo-tolerant: "chiken curry" and "panir tika" work.
- **Portions the way people eat:**
  - katori, bowl, plate, piece or grams;
  - egg curry by the egg (+ gravy);
  - chicken, mutton and fish curries by a small, medium or large piece with gravy;
  - tandoori chicken by the leg piece, drumstick or wing.
  - Amounts read naturally: "2 eggs + gravy", "2 pieces".
- **Oil and ghee in one tap.** Low, home style or extra, on cooked dishes.
- **Saved meals** (your usual thali in one tap), **quick add** (just the calories, from a label), and **recent dishes again in one tap**.
- **The day's meals.** Edit or delete any entry with one-tap **Undo**, repeat yesterday's meal, or save a meal as a favourite.

### Train

- **Your plan.** Choose where you train (a gym, dumbbells at home, or no equipment), how long you've trained, and 3–6 days a week. **Sunday is always rest.** Change it any time, for when you start or stop going to the gym.

  | Days | Week |
  |---|---|
  | 3 | Full body A, B, C on Monday, Wednesday, Friday |
  | 4 | Upper A, Lower A, Upper B, Lower B |
  | 5 | Push, Pull, Legs, Upper, Lower |
  | 6 | Push, Pull, Legs, twice, Monday to Saturday |

  - Plans come from rules on the phone, never AI.
  - Each move (squat, hinge, push, pull…) picks the exercise for the place, and an easier variation for people new to training.
  - Big lifts get more sets and 90 s rest.
- **51 standard exercises**, each with two or three how-to cues:
  - Home: chair and bodyweight squats, push-ups, pike push-ups, doorframe rows, towel curls, dips, planks.
  - Dumbbells: goblet squats, RDLs, rows, presses, curls.
  - Gym: leg press, squat, bench, pulldown, cable row and machines.
- **Week strip.** Each day's workout, rest or active rest, with done days ticked.
- **Workout screen:**
  - Every set with reps (or seconds) and kilos, filled in from last time.
  - When every set reached the top of the range, the weight goes up a step (double progression).
  - A rest timer after each set, and Josh counting the sets.
  - Finishing saves it. Leaving part-way asks whether to save.
- **Step counter.** "Count my steps" uses the phone's own step sensor, checked every 15 minutes even with the app closed. It only ever raises a day's steps, so a number you typed stays.

### Progress

- **Josh's streak.** A day counts when you log a meal or a workout. Missing a day only pauses the streak; it never resets. Josh grows at 7, 30 and 60 days: cub, getting going, fit, beast mode.
- **Calendar:**
  - Days logged show Josh's fiery eyes; days missed get a grey dot ("no log, no guilt").
  - Tap any day and Josh says in a speech bubble how it went, over that day's goals.
- **Weight trend.** The last 12 weeks, with the 7-day average line, in plain words ("1.2 kg down since 3 September").

### Account and privacy

- **My details.** Edit the profile and goal on one screen. Targets update; old goals stay with their formula.
- **Export my data.** All of it, as JSON and CSV, built on the phone, offline, through the share sheet.
- **Delete account.** Deletes the account and everything in it, on the server and the phone.
- **Crash reports** carry where the app broke and the phone model, never meals or the email address, and can be switched off in the account sheet. They need Firebase set up, as described in [What's left](#whats-left).
- **Legal pages.** Privacy and terms are linked from the app, and the app says it isn't medical advice.

### Josh, and how it feels

- **Josh** is drawn in code, with no images:
  - six moods: happy, fired, sweaty, proud, sleepy, calm;
  - four body stages that grow with the streak.
  - He's never sad or cross.
  - He moves for a few seconds when a tab opens, or when you log something, then rests, so he doesn't drain the battery.
- **The look:**
  - A soft near-black with bright cards in orange, mint, sky, lilac and yellow.
  - DM Sans for text and Barlow Condensed for headlines, bundled so every phone shows the same font.
  - Every text colour passes WCAG AA contrast.
- **Motion:**
  - The orange tab pill slides between tabs, and you can drag it.
  - Cards rise in one after another, numbers count up, and rings and bars fill.
  - The weight line draws itself in, and buttons press in under your finger.
  - Haptics on logs and tab changes.
  - With "reduce animations" on, everything stands still.
- **Large text.** Every screen is checked at 1.3× text size.

## Architecture

```
 Phone (Flutter, Android)                              Supabase (Mumbai)
┌───────────────────────────────────────┐      ┌───────────────────────────────────┐
│ features/   screens and widgets       │      │ Auth     Google, email + code     │
│     │  Riverpod providers             │      │                                   │
│ data/       repositories              │      │ Postgres + row-level security     │
│     │                                 │      │   profiles, goals, weight_logs,   │
│ Drift (SQLite, schema v5)             │ sync │   meal_entries, saved_meals,      │
│   every table the account has,        │◀────▶│   saved_meal_items,               │
│   plus the food catalogue             │ seq  │   health_samples, workout_sessions│
│                                       │      │   foods (shared, read-only)       │
│ services/   rules in plain Dart:      │      │   ai_usage, ai_calls,             │
│   targets, goals, coach, workouts,    │      │   ai_daily_totals (server only)   │
│   food search, export                 │      │                                   │
│                                       │ HTTPS│ Edge Functions (Deno)             │
│ Android (Kotlin): share sheet,        │─────▶│   parse-meal  ──▶ Gemini 3.5      │
│   step sensor + WorkManager           │ +JWT │   delete-account   Flash-Lite     │
└───────────────────────────────────────┘      └───────────────────────────────────┘
```

### On the phone

- **Offline first.** Screens read and write the phone's own database (Drift on SQLite) and never wait for the network.
  - Every row has a UUIDv7 id.
  - Every change marks the row `dirty`.
  - Deletes are soft (`deleted_at`), so they sync too.
- **State and navigation:**
  - Riverpod 3 providers watch the database's streams, so screens update on their own.
  - go_router holds the four tabs in a `StatefulShellRoute`. Each keeps its place, and the logger, the workout screen and the setup screens open over them.
- **Layers:**
  - `features/` holds the screens.
  - `data/` holds the repositories: profile, log, food, workout and account.
  - `services/` holds the rules as plain, tested Dart: targets, goals, coach lines, workout plans, the step bridge and the export.
  - `widgets/` holds the shared pieces: Josh, cards, motion, the portion picker.
- **Food search** runs in memory over the bundled catalogue. It tries exact matches first, then Hinglish spelling folded (`foldSpelling`), then near misses (`editDistance`), each worked out once per food.
- **Native Android.**
  - `MainActivity.kt` shares export files through a `FileProvider`.
  - `StepCounter.kt` reads `TYPE_STEP_COUNTER` and keeps timed readings, every 15 minutes through WorkManager and whenever the app asks. A day's steps are how much the count grew within the day.

### Sync

- **Each table syncs on its own.** It pushes its `dirty` rows, then pulls everything newer than its cursor. The server stamps every write with a sequence number (`seq`, through the `sync_stamp` trigger).
- **The newer write wins.** On the phone, stamp-forward triggers make sure a later edit there always moves its stamp ahead.
- **Unique rows.** The active goal, and one weigh-in per day, keep only one live row: the loser of a clash is retired, not lost.
- **The food catalogue** syncs the same way, by `seq`. The phone starts from the copy bundled in the app (`app/assets/foods.json`) and fetches only foods changed or added after it.

### On the server

- **Row-level security** on every table of a person's data. Each has three policies (read, add and change your own rows, when signed in and not anonymous) and the sync trigger. `supabase/tests/security_test.sql` checks all of it.
- **AI.**
  - The app sends the typed meal to `parse-meal` with the user's sign-in token. The function calls Gemini 3.5 Flash-Lite, with the key held as a server secret.
  - Per-user and app-wide daily limits are enforced in the database, and a call that fails upstream is refunded.
  - Only counts and outcomes are logged, never the meal text.
  - The app matches the result against the verified food list before showing it.
- **`delete-account`** removes the user. Their rows go with them through `on delete cascade`.

### The food catalogue

- **The generator.** `app/tool/build_food_catalogue.py` writes `app/assets/foods.json` from four lists:
  - the original seed;
  - `LATER_FIXES`, changes to seeded foods;
  - `ADDED_FOODS`, new foods;
  - each with the `seq` the server gave it.
- **The server's copy** comes from migrations. CI applies every migration to Postgres and checks the server's catalogue matches `foods.json` row for row (`supabase/tests/check_catalogue.py`).

### CI (GitHub Actions)

- **Flutter app:** `dart format`, `flutter analyze --fatal-infos`, and all tests (unit, database, migration and widget).
- **Edge Functions:** Deno tests.
- **Supabase:** every migration applied to plain Postgres, then the security, sync and catalogue checks.
- **Website** (`frontend/`): a Next.js static export to GitHub Pages, with the privacy, terms and account deletion pages Play needs.

## Repository layout

```
app/                         the Flutter app (more in app/README.md)
├── lib/
│   ├── core/                theme, router, links, error reporting, formatting
│   ├── data/                Drift tables, repositories, sync engine
│   ├── features/            intro, onboarding, targets, account, shell (tabs),
│   │                        today, food, nutrition (logger), train, progress
│   ├── services/            targets, goals, coach rules, workouts, steps, export
│   ├── widgets/             Josh, bright cards, motion, portion picker
│   └── models/options.dart  every fixed choice, stored as the server allows
├── android/                 MainActivity.kt, StepCounter.kt, signing, R8 rules
├── assets/                  foods.json, fonts and their licences
├── test/                    unit, database, migration and widget tests
└── tool/                    food catalogue generator, screenshots, icon, Josh sheet
supabase/
├── migrations/              the schema and catalogue, one SQL file per change
├── functions/               parse-meal, delete-account, shared Gemini adapter
└── tests/                   security, sync and catalogue checks, Postgres shim
frontend/                    the website: landing, privacy, terms, account deletion
docs/                        the PRD and decision records
```

## Run, test and build

The app finds its server through `app/env/supabase.json`, which stays out of git. Copy `app/env/supabase.example.json` there and fill in the project's URL, its publishable key and Google's web client ID. All three are public by design, and row-level security guards everything behind them. A build without the file runs, but can't sign in, and says so.

```bash
cd app
flutter pub get
flutter run --dart-define-from-file=env/supabase.json    # a phone or an emulator
flutter test                                             # every test, no network
flutter test tool/screenshots_test.dart                  # every screen to build/screenshots/
```

To install on a phone, or send to a tester, build an APK:

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=env/supabase.json
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

To release on Google Play, follow `app/README.md`: an upload key, an app bundle, and Play's signing SHA-1 for Google sign-in.

The database checks run in CI. On a Supabase project, paste `supabase/tests/security_test.sql`, then `supabase/tests/sync_test.sql`, into the SQL editor; each rolls itself back.

## Rules for changing things

- **Never edit an applied migration.** Supabase won't run it again, so the phone and the server would drift apart. Add a new migration instead.
- **After applying a migration to the live project,** rename its file to the version Supabase recorded.
- **To change or add a food:**
  1. Add a migration that updates or inserts it, letting `foods_seq` number it.
  2. Add the change to `LATER_FIXES` or `ADDED_FOODS` with that number.
  3. Run the generator. CI then checks the two match.
- **To change the phone's schema:**
  1. Bump `schemaVersion`.
  2. Add a migration step.
  3. Run `dart run drift_dev make-migrations`, and add the matching SQL migration.
- **After adding a native Android library,** check the release build on a real phone. R8 shrinking can strip what tests never touch: WorkManager's database needed `proguard-rules.pro`.
- **Process:** one branch and one pull request per piece of work, so CI checks it before it lands. No secrets in git: `env/supabase.json`, `key.properties`, the keystore and `google-services.json` are all ignored.

## What's left

### To share with testers (setup only you can do)

- [ ] **Google Play.** A Play Console account ($25, once) and an upload key.
  - Release builds are signed with this computer's debug key until `android/key.properties` exists.
  - Testers who install today's APK will need to reinstall once the upload key is used.
  - Internal testing then gives testers a Play link with automatic updates.
- [ ] **Google sign-in from Play.** After the first upload, add Play's app-signing SHA-1 as an Android OAuth client, or Google sign-in fails silently on Play installs.
- [ ] **Email sign-in at scale.** Supabase's built-in email sends only a few messages an hour. Set up custom SMTP with a domain, and the Site URL.
- [ ] **The website on GitHub Pages.** Switch Pages on and set the `CONTACT_EMAIL` repository variable. Play needs the privacy and deletion pages live.
- [ ] **Crash reports.** Add `google-services.json` from a Firebase project.
- [ ] **Gemini.** Make sure the key is on a paid tier, because the free tier may use prompts for training.
- [ ] **Supabase.** Move the project to Pro, in its own organisation, before real users: daily backups, and no pausing.

**Sharing today, before Play:**
1. Send `app-arm64-v8a-release.apk` as a document on WhatsApp.
2. The tester allows "Install unknown apps" and taps "Install anyway".
3. For each new version, build it on the same computer and send it again.

### Left from the "Your trainer" milestone

- [ ] **Cook it yourself.** Your own dish from its ingredients ("makes 3 katori"), saved for logging again. It needs `my_dishes` and `my_dish_ingredients` tables.
- [ ] **Food for training.** What to eat before and after a workout, on Today, matched to your diet.
- [ ] **Sunday check-in.** The week in review: weight trend, workouts done, goals hit, with Josh.
- [ ] **Exercises:** pictures or a body map; swapping an exercise; a custom workout; workout history and personal bests.
- [ ] **Safety:**
  - A pain or injury question that leaves out exercises and suggests a physiotherapist.
  - One review of the plans by a certified strength coach.
- [ ] **The streak by plan days.** Once people train, count days on plan (rest days included), as the plan doc proposes.

### PRD P1 (about three months after launch)

- [ ] N6: meal photo scan, checked against a 100-meal weighed Indian benchmark.
- [ ] N10: an anonymous count of searches that found nothing, to grow the food list.
- [ ] D5: an Android home-screen widget.
- [ ] D7: a weekly calorie budget, borrowable across days.
- [ ] C1–C2: an AI coach chat, released only after a 50-prompt safety check.
- [ ] R1: meal and water reminders, with quiet hours.

### PRD P2

- [ ] N7: barcode scanning.
- [ ] D6: a shareable Sunday summary card.
- [ ] C3: "What should I eat next?" with three options.
- [ ] C4: an adaptive weekly calorie target after 14 days.
- [ ] Health Connect sync (and HealthKit on iOS).
- [ ] Hindi UI.
- [ ] The iOS release.

### Known gaps

- **Phone steps** only count from the moment the permission is given, so the first day is partial.
- **Older builds** can't read steps marked as counted by the phone. Every phone signed in to an account should run the latest build.
- **Formula v2's numbers** (the BMI 30 blend, the deficit caps, the fat minimum) are built as the PRD proposed and still need confirming.
- **`FoodRepository`** reads `assets/foods.json` from the working directory before the app bundle. That's test plumbing in production code; tests should pass the loader instead.
- **No real-phone accessibility pass yet.** Screen-reader labels are tested in widget tests; a full TalkBack pass on a phone is still to do.
- **The PRD PDF** (`docs/AURA-FIT-AI-PRD.pdf`) is in a public repository. That's fine if it's meant to be public.
