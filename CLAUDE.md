# CLAUDE.md - Exercise Tracker (Move Now) QA

This document provides essential context for AI assistants working with this codebase.

## Project Overview

**Exercise Tracker (Move Now)** is a multi-platform Flutter application for tracking daily exercise goals by body part categories. It supports iOS native deployment and Progressive Web App (PWA) deployment with optional Firebase cloud sync.

**QA Version Note:** This repository is configured for QA/testing mode, which runs without Firebase dependencies for pure UI testing.

## Quick Reference

| Item | Value |
|------|-------|
| Language | Dart |
| Framework | Flutter 3.27.0 |
| Dart SDK | >=3.0.0 <4.0.0 |
| State Management | Provider (ChangeNotifier) |
| Local Storage | Hive (encrypted in production) |
| Cloud Backend | Firebase (Firestore + Auth) |
| Platforms | iOS, Web (PWA) |

## Project Structure

```
exercise-tracker-qa/
├── lib/                           # Main source code
│   ├── main.dart                  # App entry point, navigation
│   ├── config/
│   │   ├── environment.dart       # QA vs Production detection
│   │   ├── firebase_config.dart   # Firebase config from dart-define
│   │   └── theme.dart             # Material Design 3 theming
│   ├── models/
│   │   ├── models.dart            # Data models (ExerciseCategory, DailyRecord, etc.)
│   │   └── models.g.dart          # Auto-generated Hive adapters (DO NOT EDIT)
│   ├── providers/
│   │   └── exercise_provider.dart # Central state management
│   ├── services/
│   │   ├── database_service.dart  # Hive local storage
│   │   ├── cloud_sync_service.dart # Firebase sync
│   │   ├── auth_service.dart      # Firebase authentication
│   │   └── secure_logger.dart     # Safe logging utilities
│   ├── screens/
│   │   ├── home_screen.dart       # Daily tracking view
│   │   ├── history_screen.dart    # Calendar view
│   │   ├── stats_screen.dart      # Records/analytics view
│   │   └── settings_screen.dart   # App settings
│   └── widgets/
│       ├── category_card.dart     # Exercise category card
│       ├── progress_ring.dart     # Circular progress indicator
│       └── qa_banner.dart         # QA environment indicator
├── ios/                           # iOS platform files
├── web/                           # PWA files, landing page
├── scripts/
│   ├── build_qa.sh               # QA build (no Firebase)
│   └── build_web.sh              # Production build
└── .github/workflows/
    └── deploy-qa.yml             # CI/CD to GitHub Pages
```

## Essential Commands

### Development
```bash
# Install dependencies
flutter pub get

# iOS setup (macOS only)
cd ios && pod install && cd ..

# Run locally
flutter run

# Run with QA mode
flutter run --dart-define=ENV=qa
```

### Building
```bash
# QA web build (no Firebase)
./scripts/build_qa.sh
# or directly:
flutter build web --release --dart-define=ENV=qa

# Local test server
cd build/web && python3 -m http.server 8080
```

### Code Generation
```bash
# Regenerate Hive adapters after modifying models.dart
flutter pub run build_runner build --delete-conflicting-outputs
```

### Analysis
```bash
# Run linter
flutter analyze

# Check for issues
flutter doctor
```

## Key Conventions

### Code Style (enforced by analysis_options.yaml)
- Use `const` constructors where possible
- Use single quotes for strings (`'text'` not `"text"`)
- NO `print()` statements - use `SecureLogger` instead
- Follow flutter_lints package rules

### File Naming
- **Files**: snake_case (e.g., `exercise_provider.dart`)
- **Classes**: PascalCase (e.g., `ExerciseProvider`)
- **Variables/functions**: camelCase (e.g., `loadRecords()`)

### Import Order
1. Dart/Flutter core imports
2. Package imports (provider, hive, etc.)
3. Local config imports
4. Local model imports
5. Local service imports
6. Local provider imports
7. Local screen/widget imports

### State Management Pattern
```dart
// UI reads state via Consumer
Consumer<ExerciseProvider>(
  builder: (context, provider, child) {
    return Text('${provider.completionPercentage}%');
  },
)

// UI triggers actions on provider
provider.incrementCategory(categoryId);
```

### Data Flow
```
UI → Provider → Services → Database (Hive)
                       ↘ Cloud (Firebase) [production only]
```

## Environment Configuration

### QA Mode (current)
- Set via `--dart-define=ENV=qa`
- Firebase initialization is skipped
- Uses unencrypted Hive storage
- Displays QA banner in UI
- Storage boxes suffixed with `_qa`

### Production Mode
- Default when ENV not set or `ENV=production`
- Requires Firebase credentials via dart-define
- Uses AES-encrypted Hive storage
- Full cloud sync capabilities

## Data Models

### Core Models (in models.dart)
- **ExerciseCategory**: Exercise type (name, icon, displayOrder)
- **CategoryProgress**: Sets completed per category
- **DailyRecord**: Full day's exercise data
- **AppSettings**: User preferences (targets, dark mode)
- **WeekdayGoals**: Per-weekday goal customization
- **MonthlySummary**: Aggregated monthly stats

### Hive TypeId Mapping (in models.g.dart)
Auto-generated file. After changing models.dart, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Architecture Decisions

1. **Provider for State**: Single `ExerciseProvider` manages all app state
2. **Hive for Local Storage**: Fast, lightweight NoSQL with encryption support
3. **Environment Separation**: QA mode allows UI testing without backend
4. **Material Design 3**: Modern Flutter UI with custom navy/green theme
5. **PWA Support**: Installable web app with offline capability

## Common Tasks

### Adding a New Screen
1. Create file in `lib/screens/` following naming convention
2. Add navigation destination in `main.dart` `MainNavigationScreen`
3. Update `NavigationBar` destinations list

### Adding a New Data Model
1. Add class to `lib/models/models.dart` with `@HiveType` annotation
2. Run code generator for Hive adapter
3. Register adapter in `database_service.dart` initialization

### Modifying Theme
Edit `lib/config/theme.dart`:
- Primary color: Navy blue (#1E3A5F)
- Secondary color: Green (#10B981)

## CI/CD Pipeline

**Trigger**: Push to `main` branch or manual dispatch

**Workflow** (deploy-qa.yml):
1. Checkout code
2. Setup Flutter 3.24.0
3. Install dependencies
4. Build web with `--dart-define=ENV=qa --base-href="/exercise-tracker-qa/"`
5. Setup landing page (landing.html → index.html, app.html → Flutter app)
6. Deploy to GitHub Pages

**Deployment URL**: `https://<username>.github.io/exercise-tracker-qa/`

## Security Considerations

- Firebase credentials passed via dart-define, never committed
- `.gitignore` excludes `.env`, `secrets/`, `credentials/`
- Production Hive data is AES-encrypted
- Firestore rules enforce user-only document access
- CSP headers configured in `web/index.html`

## Troubleshooting

### Hive Adapter Errors
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### iOS Build Issues
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### Web Build CORS Issues
Run a local server instead of opening file directly:
```bash
cd build/web && python3 -m http.server 8080
```

## Dependencies Overview

### Core
- `flutter` - UI framework
- `provider` ^6.1.1 - State management

### Storage
- `hive` ^2.2.3 - Local NoSQL database
- `hive_flutter` ^1.1.0 - Flutter integration
- `hive_generator` ^2.0.1 (dev) - Code generation

### Firebase (production only)
- `firebase_core` ^3.9.0
- `cloud_firestore` ^5.6.0
- `firebase_auth` ^5.4.0
- `google_sign_in` ^6.2.2

### Utilities
- `intl` ^0.18.1 - Date formatting
- `uuid` ^4.2.1 - ID generation
- `cupertino_icons` ^1.0.6

## Testing Notes

No test files currently exist. When adding tests:
- Unit tests go in `test/` directory
- Widget tests use `flutter_test` package
- Run with `flutter test`

## Related Documentation

- [README.md](README.md) - User setup guide
- [README_PWA.md](README_PWA.md) - PWA deployment guide
- [firestore.rules](firestore.rules) - Firebase security rules
