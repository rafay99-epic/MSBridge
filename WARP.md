# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

MSBridge is a cross-platform Flutter application for lecture note reading and note-taking with online/offline capabilities. It integrates Firebase for authentication and data sync, uses Hive for local storage, and includes AI-powered features for note summarization.

## Common Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run the application in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload (during development)
# Press 'r' in terminal or use IDE hot reload

# Hot restart (during development)
# Press 'R' in terminal or use IDE hot restart
```

### Code Analysis & Testing
```bash
# Analyze code for issues
flutter analyze

# Run linter
flutter pub run flutter_lints

# Generate code (for Hive adapters)
flutter packages pub run build_runner build

# Watch and regenerate code on changes
flutter packages pub run build_runner watch
```

### Building
```bash
# Build APK for Android
flutter build apk

# Build signed APK (requires keystore setup)
flutter build apk --release

# Build for iOS (requires macOS and Xcode)
flutter build ios

# Build web version
flutter build web
```

### Device Management
```bash
# List connected devices
flutter devices

# List available emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>
```

## Architecture Overview

### High-Level Structure

MSBridge follows a feature-based architecture with clear separation of concerns:

- **`lib/main.dart`**: Application entry point with Provider setup and Firebase initialization
- **`lib/features/`**: Feature-specific UI and business logic organized by functionality
- **`lib/core/`**: Shared business logic, models, services, and utilities
- **`lib/config/`**: Configuration files including API keys and Firebase settings
- **`lib/theme/`**: Theming and UI styling
- **`lib/widgets/`**: Reusable UI components

### Key Architectural Patterns

#### Provider Pattern for State Management
The app uses Flutter Provider for state management with multiple providers:

- **ThemeProvider**: Manages app themes and dynamic colors
- **ConnectivityProvider**: Handles network connectivity state
- **NoteSummaryProvider**: AI-powered note summarization
- **TodoProvider**: Task management functionality
- **AuthProviders**: Authentication and pin lock functionality

#### Repository Pattern
- **`lib/core/repo/`**: Contains repositories that abstract data access
- **`lib/core/auth/`**: Authentication logic and user management

#### Database Layer
- **Hive**: Local NoSQL database for offline storage
- **Firebase Firestore**: Cloud database for data synchronization
- **`lib/core/database/`**: Database models and adapters organized by feature

#### Service Layer
- **`lib/core/services/`**: Background services, network handling, sync, notifications
- **Background Processing**: Uses Workmanager for background tasks
- **Auto-sync**: Scheduled synchronization between local and cloud data

### Feature Organization

Each feature in `lib/features/` typically contains:
- Main feature widget/screen
- Feature-specific widgets in `widgets/` subdirectory
- Business logic and state management
- Models specific to the feature

Key features:
- **`msnotes/`**: Note reading functionality
- **`notes_taking/`**: Note creation and editing
- **`ai_summary/`**: AI-powered note summarization
- **`ai_chat/`**: AI chat functionality
- **`auth/`**: User authentication flows
- **`setting/`**: App configuration and preferences

### Data Flow

1. **Offline-first approach**: Data is primarily stored locally with Hive
2. **Background sync**: Workmanager schedules periodic syncing with Firebase
3. **Real-time updates**: Firebase provides real-time synchronization when online
4. **Connectivity awareness**: App adapts behavior based on network state

## Configuration

### Firebase Setup
- Configuration is in `lib/config/config.dart`
- Firebase options in `firebase_options.dart`
- Requires `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

### API Keys
- AI features require Google AI Studio API key
- Keys should NOT be stored in source. Provide them via --dart-define (Flutter) or CI env.
- Example:
    flutter run --dart-define=AI_STUDIO_API_KEY=${AI_STUDIO_API_KEY}
- And read with const String.fromEnvironment('AI_STUDIO_API_KEY').
### Build Configuration
- Android: `android/app/build.gradle`
- iOS: `ios/Runner.xcodeproj`
- Keystore for signed builds (password required separately)

## Important Development Notes

### Code Generation
The app uses code generation for Hive adapters. After modifying database models, run:
```bash
flutter packages pub run build_runner build
```

### State Management
- Use Provider.of<T>(context) for accessing providers
- Providers are configured in `main.dart`
- State changes trigger UI rebuilds automatically

### Offline Capabilities
- All features should work offline using Hive storage
- Use connectivity state to determine sync behavior
- Handle network errors gracefully

### Performance Considerations
- Home screen uses lazy loading for tabs
- RepaintBoundary widgets prevent unnecessary repaints
- Page caching reduces navigation lag

### Theme System
- Supports multiple themes including dynamic colors
- Theme state persisted in SharedPreferences
- Material 3 design system implementation

## Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests (if available)
flutter test integration_test/
```

### Device Testing
```bash
# Install on connected device
flutter install

# Run on specific device
flutter run -d <device-id>
```
