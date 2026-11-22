# AURA FIT AI: the Flutter app

Android first, offline first: every screen reads and writes the phone's own database (Drift), and Supabase gets a copy once sync arrives in February 2027.

## Where things are

| Path | What it holds |
|------|---------------|
| `lib/services/targets.dart` | The calorie maths, formula v1, with the safe floor |
| `lib/services/rounding.dart` | Rounding that matches Python's `round()` |
| `lib/models/options.dart` | Every fixed choice, stored by the string the server also allows |
| `lib/data/db/` | The Drift tables, matching `supabase/migrations/` |
| `lib/data/profile_repository.dart` | Saving onboarding, goals and weigh-ins |
| `lib/features/` | Onboarding and the targets screens |
| `tool/export_python_targets.py` | Records the old Python maths' answers for the parity test |
| `tool/screenshots_test.dart` | Draws every screen, at normal and large text |

## Commands

```bash
flutter test                                # every test
flutter test tool/screenshots_test.dart     # screenshots to build/screenshots/
dart run build_runner build                 # after changing a Drift table
dart format lib test tool                   # CI fails on unformatted code
```

To change the database schema, bump `schemaVersion` in `lib/data/db/app_database.dart`, add a migration step, then run `dart run drift_dev make-migrations` so the new step gets a generated test. Add the matching SQL migration in `supabase/migrations/`.
