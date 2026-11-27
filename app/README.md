# AURA FIT AI: the Flutter app

Android first, offline first: every screen reads and writes the phone's own database (Drift), and sync copies it to the Supabase account.

## Where things are

| Path | What it holds |
|------|---------------|
| `lib/services/targets.dart` | The calorie maths, formula v1, with the safe floor |
| `lib/services/rounding.dart` | Rounding that matches Python's `round()` |
| `lib/models/options.dart` | Every fixed choice, stored by the string the server also allows |
| `lib/data/db/` | The Drift tables, matching `supabase/migrations/` |
| `lib/data/profile_repository.dart` | Saving onboarding, goals and weigh-ins |
| `lib/features/` | Onboarding and the targets screens |
| `tool/screenshots_test.dart` | Draws every screen, at normal and large text |
| `lib/widgets/josh.dart` | Josh, the mascot: a bear drawn in code, with four streak stages and six moods |
| `lib/features/intro/` | Josh's five-screen intro before onboarding |
| `lib/features/shell/` | The four tabs (Today, Train, Food, Progress) and the Yesterday/Today switch they share |
| `lib/features/today/` | Today: Josh's card, calories, protein, water, steps, weight; and the water, steps and weight sheets |
| `lib/features/food/` | Food: type a meal for AI, search, saved meals, quick add, and the day's meals to edit |
| `lib/features/progress/` | Progress: Josh's streak, the calendar of days logged, the weight trend |
| `lib/features/train/` | Train: Josh until workouts arrive, and today's steps |
| `lib/widgets/motion.dart` | The shared motion: cards that rise in, numbers that count, presses; all still when the phone asks for less motion |
| `tool/build_food_catalogue.py` | The food list: the seed, later fixes (`LATER_FIXES`) and added foods (`ADDED_FOODS`), written to `assets/foods.json` |
| `tool/render_josh_test.dart` | Draws every stage and mood of Josh to `build/josh/sheet.png` |

## Commands

```bash
flutter test                                # every test
flutter test tool/screenshots_test.dart     # screenshots to build/screenshots/
dart run build_runner build                 # after changing a Drift table
dart format lib test tool                   # CI fails on unformatted code
```

## Crash reports

Release builds send crashes to Firebase Crashlytics when `android/app/google-services.json` is present (download it from the Firebase console; it's gitignored). Without it, the app builds and runs the same, with crash reports off. Only `lib/core/error_reporter.dart` may talk to Firebase, and it sends where the error happened, its type and the stack, never its message. A test enforces both.

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
