# CLAUDE.md - AI Assistant Guide for Exercise Tracker

This document provides essential context for AI assistants working on this codebase.

## Project Overview

**Exercise Tracker (Move Now)** is a Flutter cross-platform fitness tracking application that helps users track daily exercise progress across customizable body part categories.

- **Primary Purpose**: Track exercise sets across 8 body part categories (Chest, Back, Shoulders, Biceps, Triceps, Legs, Abs, Cardio)
- **Platforms**: iOS, Web (PWA), with potential for Android
- **Key Features**: Daily tracking, calendar history, monthly statistics, cloud sync, dark mode

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.24.0+ (Dart >=3.0.0 <4.0.0) |
| State Management | Provider (ChangeNotifier pattern) |
| Local Storage | Hive (with AES encryption in production) |
| Cloud Backend | Firebase (Firestore, Authentication) |
| Authentication | Google Sign-In via Firebase Auth |
| CI/CD | GitHub Actions → GitHub Pages |

## Project Structure

```
lib/
├── main.dart                    # App entry point, routing, error handling
├── config/
│   ├── environment.dart         # QA vs Production environment config
│   ├── firebase_config.dart     # Firebase credentials (compile-time)
│   └── theme.dart               # Material 3 light/dark themes
├── models/
│   ├── models.dart              # Data models (ExerciseCategory, DailyRecord, AppSettings)
│   └── models.g.dart            # Generated Hive type adapters
├── providers/
│   └── exercise_provider.dart   # Central state management
├── screens/
│   ├── home_screen.dart         # Daily tracking interface
│   ├── history_screen.dart      # Calendar view with monthly progress
│   ├── stats_screen.dart        # Records and statistics
│   └── settings_screen.dart     # User preferences
├── services/
│   ├── database_service.dart    # Hive local storage operations
│   ├── auth_service.dart        # Firebase Authentication
│   ├── cloud_sync_service.dart  # Firestore real-time sync
│   └── secure_logger.dart       # Debug-safe logging
└── widgets/
    ├── category_card.dart       # Exercise category UI component
    ├── progress_ring.dart       # Circular progress indicator
    └── qa_banner.dart           # QA environment visual indicator
```

## Key Files for Common Tasks

| Task | Primary File(s) |
|------|-----------------|
| Add new data model | `lib/models/models.dart` then run `flutter pub run build_runner build` |
| Change exercise categories | `lib/services/database_service.dart` → `_initializeDefaultData()` |
| Modify theme/colors | `lib/config/theme.dart` |
| Add new screen | Create in `lib/screens/`, add to `main.dart` navigation |
| Change default targets | `lib/models/models.dart` → `AppSettings` class |
| Update Firestore rules | `firestore.rules` |

## Development Commands

```bash
# Install dependencies
flutter pub get

# Run in development (defaults to production mode)
flutter run

# Run in QA mode (no Firebase)
flutter run --dart-define=ENV=qa

# Build QA web (local testing)
flutter build web --release --dart-define=ENV=qa

# Build production web (requires Firebase env vars)
./scripts/build_web.sh

# Regenerate Hive adapters after model changes
flutter pub run build_runner build --delete-conflicting-outputs

# iOS setup
cd ios && pod install && cd ..

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Environment Configuration

The app supports two environments controlled via `--dart-define=ENV=<value>`:

| Environment | Value | Firebase | Use Case |
|-------------|-------|----------|----------|
| Production | `production` (default) | Enabled | Live deployment |
| QA | `qa`, `staging`, `test` | Disabled | UI testing, GitHub Pages demo |

**Environment-specific behaviors** (`lib/config/environment.dart`):
- `EnvironmentConfig.skipFirebase` - Returns `true` in QA, skips Firebase initialization
- `EnvironmentConfig.appName` - Returns "Move Now (QA)" or "Move Now"
- Database uses separate Hive box names in QA to avoid data conflicts

## Coding Conventions

### Dart/Flutter Style

Follow `analysis_options.yaml` rules:
- **Prefer `const`**: Use `const` constructors and literals where possible
- **No `print()` statements**: Use `SecureLogger` for debugging
- **Single quotes**: Use `'single quotes'` for strings
- **Follow flutter_lints**: Package rules are enforced

### Architecture Patterns

1. **State Management**: Use `Provider` with `ChangeNotifier`
   - Central state in `ExerciseProvider`
   - Access via `Provider.of<ExerciseProvider>(context)` or `context.watch/read`

2. **Service Layer**: Business logic in services, not in widgets
   - `DatabaseService` for local storage
   - `CloudSyncService` for Firestore operations
   - `AuthService` for authentication

3. **Widget Composition**: Small, reusable widgets in `lib/widgets/`

### Naming Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Private members: `_prefixedWithUnderscore`
- Constants: `camelCase` (Dart convention, not SCREAMING_CASE)

## Data Models

### Core Models (`lib/models/models.dart`)

```dart
ExerciseCategory    // Body part with name, icon, target sets
DailyRecord         // Daily tracking data with category progress
AppSettings         // User preferences (targets, dark mode, weekday goals)
CategoryProgress    // Sets completed for a specific category
```

### Hive Type IDs

When adding new models, use the next available type ID:
- 0: ExerciseCategory
- 1: DailyRecord
- 2: AppSettings
- 3: CategoryProgress

## Firebase/Firestore

### Security Rules (`firestore.rules`)

- Default deny all access
- Authenticated users can only read/write their own data under `/users/{userId}/`

### Data Structure

```
users/{userId}/
├── settings (document)
├── categories/ (subcollection)
│   └── {categoryId}
└── daily_records/ (subcollection)
    └── {date-string}
```

## Deployment

### QA (GitHub Pages) - Automatic

Pushes to `main` trigger `.github/workflows/deploy-qa.yml`:
1. Build with `--dart-define=ENV=qa`
2. Deploy to GitHub Pages at `/{repo-name}/`

### Production - Manual

1. Set Firebase environment variables (see `.env.example`)
2. Run `./scripts/build_web.sh`
3. Deploy: `firebase deploy --only hosting`

## Common Pitfalls

1. **Forgetting to regenerate Hive adapters**: After modifying models with `@HiveType`, run build_runner
2. **Wrong environment in testing**: Ensure `--dart-define=ENV=qa` for local testing without Firebase
3. **iOS pod issues**: Run `cd ios && pod install --repo-update && cd ..`
4. **Null safety**: All code is null-safe; avoid `!` operator where possible

## Testing

### Current State
No automated tests exist yet. Flutter test infrastructure is set up.

### Recommended Testing Approach
- Unit tests for models and services
- Widget tests for UI components
- Integration tests for user flows

### QA Testing
The QA environment on GitHub Pages serves as a manual testing ground with:
- Local-only storage (no Firebase)
- Visual QA banner indicator
- Separate data from production

## Security Considerations

1. **No hardcoded secrets**: Firebase credentials via compile-time `--dart-define`
2. **Local encryption**: Production uses AES-encrypted Hive storage
3. **Firestore rules**: UID-based access control
4. **Excluded files**: `.env*`, credentials never committed

## Getting Help

- Flutter docs: https://docs.flutter.dev
- Provider package: https://pub.dev/packages/provider
- Hive docs: https://docs.hivedb.dev
- Firebase Flutter: https://firebase.flutter.dev
