# CLAUDE.md - AI Assistant Guide for Exercise Tracker

This document provides essential context for AI assistants working on this codebase.

## Project Overview

**Exercise Tracker (Move Now)** is a Flutter cross-platform fitness tracking application that helps users track daily exercise progress across customizable body part categories.

- **Primary Purpose**: Track exercise sets across 8 body part categories (Chest, Back, Shoulders, Biceps, Triceps, Legs, Abs, Cardio)
- **Platforms**: iOS, Web (PWA), with potential for Android
- **Key Features**: Daily tracking, calendar history, monthly statistics, cloud sync, dark mode, weekday-specific goals

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.24.0+ (Dart >=3.0.0 <4.0.0) |
| State Management | Provider 6.1.1+ (ChangeNotifier pattern) |
| Local Storage | Hive 2.2.3 (with AES encryption in production) |
| Cloud Backend | Firebase (Firestore 5.6.0+, Authentication 5.4.0+) |
| Authentication | Google Sign-In 6.2.2+ via Firebase Auth |
| CI/CD | GitHub Actions → GitHub Pages |

## Project Structure

```
lib/
├── main.dart                    # App entry point, routing, error handling
├── config/
│   ├── environment.dart         # QA vs Production environment config
│   ├── firebase_config.dart     # Firebase credentials (compile-time)
│   └── theme.dart               # Material 3 light/dark themes, 5-tier colors
├── models/
│   ├── models.dart              # Data models (7 classes total)
│   └── models.g.dart            # Generated Hive type adapters
├── providers/
│   └── exercise_provider.dart   # Central state management (~610 lines)
├── screens/
│   ├── home_screen.dart         # Daily tracking interface (2-column cards)
│   ├── history_screen.dart      # Calendar view with monthly progress
│   ├── stats_screen.dart        # Records, bar chart, period selector
│   └── settings_screen.dart     # User preferences, weekday goals
├── services/
│   ├── database_service.dart    # Hive local storage operations
│   ├── auth_service.dart        # Firebase Authentication
│   ├── cloud_sync_service.dart  # Firestore real-time sync
│   └── secure_logger.dart       # Debug-safe logging
└── widgets/
    ├── category_card.dart       # Exercise category UI component
    ├── progress_ring.dart       # Circular progress indicator
    └── qa_banner.dart           # QA environment visual indicator

web/
├── index.html                   # Flutter web entry (becomes app.html in CI)
├── landing.html                 # PWA landing page (becomes index.html in CI)
├── manifest.json                # PWA manifest
└── icons/                       # App icons (192, 512, maskable variants)

scripts/
├── build_web.sh                 # Production build script
└── build_qa.sh                  # QA build script

.github/workflows/
└── deploy-qa.yml                # GitHub Actions CI/CD for QA deployment
```

## Key Files for Common Tasks

| Task | Primary File(s) |
|------|-----------------|
| Add new data model | `lib/models/models.dart` then run `flutter pub run build_runner build` |
| Change exercise categories | `lib/services/database_service.dart` → `_initializeDefaultData()` |
| Modify theme/colors | `lib/config/theme.dart` |
| Add new screen | Create in `lib/screens/`, add to `main.dart` navigation |
| Change default targets | `lib/models/models.dart` → `WeekdayGoals` class |
| Update weekday goals logic | `lib/models/models.dart` → `WeekdayGoals`, `lib/providers/exercise_provider.dart` |
| Update Firestore rules | `firestore.rules` |
| Modify progress colors | `lib/config/theme.dart` → `getProgressColor()` |

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
- Database uses separate Hive box names in QA to avoid data conflicts (e.g., `categories_qa` vs `categories_v2`)

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

#### Hive-Persisted Models

| Model | TypeId | Description |
|-------|--------|-------------|
| `ExerciseCategory` | 0 | Body part with name, icon, displayOrder, isActive |
| `CategoryProgress` | 1 | Sets completed for a specific category (categoryId, strokesCompleted) |
| `DailyRecord` | 2 | Daily tracking data with category progress list |
| `AppSettings` | 3 | User preferences (legacy targetSets, repsPerSet, darkMode, lastSyncDate) |
| `WeekdayGoals` | 4 | Per-weekday exercise targets (Monday-Sunday) |

#### Non-Persisted Models

| Model | Description |
|-------|-------------|
| `CategoryMonthlyStats` | Per-category statistics for a month (totalSets, averagePercentage, daysWithActivity) |
| `MonthlySummary` | Monthly aggregated data (averagePercentage, daysTracked, totalStrokes, categoryStats) |

### WeekdayGoals API

The `WeekdayGoals` model allows setting different targets for each day of the week:

```dart
// Days: 1 = Monday, 7 = Sunday
WeekdayGoals goals = WeekdayGoals(
  useWeekdayGoals: true,           // Enable per-day goals
  defaultSetsPerCategory: 4,       // Fallback when disabled
  weekdaySets: {1: 4, 2: 4, ...},  // Day -> sets mapping
);

// Key methods
goals.getSetsForWeekday(1);      // Get sets for Monday
goals.getSetsForDate(DateTime.now()); // Get sets for specific date
goals.hasGoalForDate(date);      // Check if day has goal (sets > 0)
```

### Hive Type IDs

When adding new models, use the next available type ID: **5**

## Theme & Colors

### 5-Tier Progress Color System

Progress visualization uses a 5-tier color system based on achievement percentage:

| Percentage | Color | Hex |
|------------|-------|-----|
| 100%+ | Green | `#22C55E` |
| 75-99% | Yellow | `#EAB308` |
| 51-74% | Amber | `#F59E0B` |
| 26-50% | Orange | `#F97316` |
| 0-25% | Red | `#EF4444` |

Access via: `AppTheme.getProgressColor(percentage)`

### Brand Colors

- Primary: Navy Blue `#1E3A5F`
- Secondary: Lighter Navy `#2D4A6F`
- Accent: Green `#10B981`

### Available Category Icons

Icons defined in `AppTheme.availableIcons`:
- `fitness_center`, `accessibility_new`, `sports_gymnastics`
- `front_hand`, `back_hand`, `directions_walk`
- `self_improvement`, `directions_run`, `sports_martial_arts`
- `sports`, `pool`, `sports_tennis`

## Firebase/Firestore

### Security Rules (`firestore.rules`)

- Default deny all access
- Authenticated users can only read/write their own data under `/users/{userId}/`

### Data Structure

```
users/{userId}/
├── settings (document)
├── weekday_goals (document)
├── categories/ (subcollection)
│   └── {categoryId}
└── daily_records/ (subcollection)
    └── {date-string}
```

### Cloud Sync Methods (`CloudSyncService`)

- `syncDailyRecord()` - Upload daily record to Firestore
- `syncSettings()` - Upload app settings
- `syncWeekdayGoals()` - Upload weekday goals
- `syncCategories()` - Upload category configuration
- `downloadFromCloud()` - Full cloud-to-local sync
- Real-time listeners for automatic sync when signed in

## Deployment

### QA (GitHub Pages) - Automatic

Pushes to `main` trigger `.github/workflows/deploy-qa.yml`:
1. Build with `--dart-define=ENV=qa`
2. Rename `index.html` → `app.html`
3. Copy `landing.html` → `index.html` (PWA landing page)
4. Deploy to GitHub Pages at `/{repo-name}/`

### Production - Manual

1. Set Firebase environment variables (see `.env.example`)
2. Run `./scripts/build_web.sh`
3. Deploy: `firebase deploy --only hosting`

## Common Pitfalls

1. **Forgetting to regenerate Hive adapters**: After modifying models with `@HiveType`, run build_runner
2. **Wrong environment in testing**: Ensure `--dart-define=ENV=qa` for local testing without Firebase
3. **iOS pod issues**: Run `cd ios && pod install --repo-update && cd ..`
4. **Null safety**: All code is null-safe; avoid `!` operator where possible
5. **Legacy vs WeekdayGoals**: `AppSettings.targetSetsPerCategory` is legacy; use `WeekdayGoals` for per-day targets

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

## UI Layout Notes

- **Home Screen**: 2-column wrap layout for category cards
- **Stats Screen**: Monthly bar chart with period selector (1, 3, 6, 12 months)
- **History Screen**: Calendar grid with daily achievement colors
- **Settings Screen**: Comprehensive settings including weekday goal configuration

## Getting Help

- Flutter docs: https://docs.flutter.dev
- Provider package: https://pub.dev/packages/provider
- Hive docs: https://docs.hivedb.dev
- Firebase Flutter: https://firebase.flutter.dev
