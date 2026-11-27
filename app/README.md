# AURA FIT AI: the Flutter app

Android first, offline first: every screen reads and writes the phone's own database (Drift), and sync copies it to the Supabase account. The [root README](../README.md) has the features, the architecture and what's left.

## Where things are

| Path | What it holds |
|------|---------------|
| `lib/core/` | The theme (colours, DM Sans and Barlow Condensed), the router, links, formatting, `error_reporter.dart` |
| `lib/models/options.dart` | Every fixed choice, stored by the string the server also allows |
| `lib/data/db/` | The Drift tables (schema v5), matching `supabase/migrations/` |
| `lib/data/sync/` | The sync engine: push dirty rows, pull by `seq`, per table |
| `lib/data/profile_repository.dart` | Onboarding, goals, weigh-ins and the training setup |
| `lib/data/log_repository.dart` | Meals, water, steps (typed and from the phone), saved meals |
| `lib/data/food_repository.dart` | The food list and its search: spelling folded, near misses, catalogue sync |
| `lib/data/workout_repository.dart` | Finished workouts and the sets done in them |
| `lib/data/providers.dart` | The Riverpod providers the screens watch |
| `lib/services/targets.dart` | The calorie maths, formulas v1 and v2, with the safe floor |
| `lib/services/goals.dart` | Today's goals and Josh's line about them |
| `lib/services/coach_rules.dart` | The calm feedback and the protein ideas |
| `lib/services/workouts.dart` | The 51 exercises and the weekly plans, by place, experience and days |
| `lib/services/step_counter.dart` | The bridge to the phone's step sensor |
| `lib/services/meal_text_parser.dart` | Typed meals: `parse-meal`, then matching against the food list |
| `lib/services/data_export.dart` | The JSON and CSV export |
| `lib/services/rounding.dart` | Rounding that matches Python's `round()` |
| `lib/features/intro/` | Josh's five-screen intro before onboarding |
| `lib/features/onboarding/`, `targets/`, `profile/`, `account/` | Onboarding, the targets and how they were worked out, My details, sign-in and the account sheet |
| `lib/features/shell/` | The four tabs (Today, Train, Food, Progress), the draggable tab pill and the Yesterday/Today switch they share |
| `lib/features/today/` | Today: Josh's card, today's goals, calories, protein, water, steps, weight; and their sheets |
| `lib/features/food/` | Food: type a meal for AI, search, saved meals, quick add, and the day's meals to edit |
| `lib/features/nutrition/` | The meal logger: search results, the portion wheel, oil, macros |
| `lib/features/train/` | Train: the training setup, the week strip, the day's exercises, the workout screen, steps |
| `lib/features/progress/` | Progress: Josh's streak, the calendar and its day bubble, the weight trend |
| `lib/widgets/josh.dart` | Josh, the mascot: a bear drawn in code, with four streak stages and six moods |
| `lib/widgets/motion.dart` | The shared motion: cards that rise in, numbers that count, bars that fill, presses; all still when the phone asks for less motion |
| `lib/widgets/portion_wheel_picker.dart` | The unit cards and number wheel for portions, and how amounts read ("2 eggs + gravy") |
| `android/app/src/main/kotlin/.../MainActivity.kt` | The share and steps channels |
| `android/app/src/main/kotlin/.../StepCounter.kt` | Step sensor readings, every 15 minutes through WorkManager |
| `android/app/proguard-rules.pro` | What R8 must keep in release builds (WorkManager's database) |
| `tool/build_food_catalogue.py` | The food list: the seed, later fixes (`LATER_FIXES`) and added foods (`ADDED_FOODS`), written to `assets/foods.json` |
| `tool/screenshots_test.dart` | Draws every screen, at normal and large text |
| `tool/render_josh_test.dart` | Draws every stage and mood of Josh to `build/josh/sheet.png` |
| `tool/render_icon_test.dart` | Draws the launcher icon |

## Commands

```bash
flutter test                                # every test
flutter test tool/screenshots_test.dart     # screenshots to build/screenshots/
dart run build_runner build                 # after changing a Drift table
dart format lib test tool                   # CI fails on unformatted code
python tool/build_food_catalogue.py         # after changing the food lists
```

## Crash reports

Release builds send crashes to Firebase Crashlytics when `android/app/google-services.json` is present (download it from the Firebase console; it's gitignored). Without it, the app builds and runs the same, with crash reports off. Only `lib/core/error_reporter.dart` may talk to Firebase, and it sends where the error happened, its type and the stack, never its message. A test enforces both.

## Sending a build to testers

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=env/supabase.json
```

Send `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. Without `android/key.properties` it's signed with this computer's debug key, so every update must be built on the same computer, and testers reinstall once when the upload key takes over.

After adding a native Android library, install a release build on a real phone and open it: R8 can strip classes that only the library reaches, which tests never see.

## Releasing to Google Play

Play takes an app bundle signed with the upload key. The key stays out of git; lose it and Play support has to reset it, which takes days, so keep two backups.

1. Once, make the upload key somewhere outside the repo, and note its SHA-1 for Google sign-in:

   ```bash
   keytool -genkey -v -keystore C:/Users/<you>/keys/aurafit-upload.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   keytool -list -v -keystore C:/Users/<you>/keys/aurafit-upload.jks -alias upload
   ```

2. Once, write `android/key.properties` (gitignored):

   ```properties
   storeFile=C:/Users/<you>/keys/aurafit-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   Without it, release builds are signed with the debug key and Play won't take them.

3. Every release, raise `version:` in `pubspec.yaml`. The number after `+` is Play's version code and must go up with every upload.
4. Build the bundle and upload `build/app/outputs/bundle/release/app-release.aab`:

   ```bash
   flutter build appbundle --release --dart-define-from-file=env/supabase.json
   ```

5. After the first upload, add Play's app-signing SHA-1 (Play Console, App integrity) to Google sign-in as its own Android OAuth client. Otherwise Google sign-in fails, with no message, on copies installed from Play.

`targetSdk` comes from Flutter (36 on Flutter 3.47.9). The launcher icon is drawn by `tool/render_icon_test.dart`; after changing it, run that test and `dart run flutter_launcher_icons`.

To change the database schema, bump `schemaVersion` in `lib/data/db/app_database.dart`, add a migration step, then run `dart run drift_dev make-migrations` so the new step gets a generated test. Add the matching SQL migration in `supabase/migrations/`.
