# Settings Sync Service

This service provides comprehensive settings synchronization between local SharedPreferences and Firebase Firestore, ensuring user settings are consistent across devices.

## Overview

The Settings Sync Service automatically syncs all user settings to Firebase under a `meta` document in the user's collection, following the existing Firebase structure used by the app.

## Features

- **Automatic Settings Sync**: Syncs all user preferences to Firebase
- **Bidirectional Sync**: Smart conflict resolution based on timestamps
- **Category-based Sync**: Sync specific setting categories (theme, streak, app settings)
- **Conflict Resolution**: Automatically resolves conflicts between local and cloud settings
- **Offline Support**: Works with local SharedPreferences when offline
- **Error Handling**: Comprehensive error handling with Firebase Crashlytics integration
- **Cloud Sync Integration**: Respects the global cloud sync setting
- **Reverse Sync Support**: Settings are synced when pulling from cloud

## Architecture

### Components

1. **UserSettingsModel** (`lib/core/models/user_settings_model.dart`)
   - Comprehensive model representing all user settings
   - Includes theme, streak, app, and sync metadata
   - JSON serialization for Firebase storage

2. **UserSettingsRepo** (`lib/core/repo/user_settings_repo.dart`)
   - Handles local SharedPreferences storage
   - Manages Firebase Firestore operations
   - Provides CRUD operations for settings

3. **UserSettingsProvider** (`lib/core/provider/user_settings_provider.dart`)
   - State management for settings
   - Notifies UI of changes
   - Provides convenient methods for setting updates

4. **SettingsSyncService** (`lib/core/services/sync/settings_sync_service.dart`)
   - Orchestrates sync operations
   - Handles conflict resolution
   - Provides sync status information

### Firebase Structure

Settings are stored in Firebase under the `meta` subcollection:
```
users/{userId}/meta/settings
```

This creates a `settings` document within the `meta` subcollection, alongside other meta documents like `streak`. The structure is:

```
users/
  {userId}/
    meta/
      settings/          # Settings document
        - appTheme
        - streakEnabled
        - notificationsEnabled
        - ... (all user preferences)
      streak/            # Streak document (existing)
        - currentStreak
        - longestStreak
        - ...
```

The settings document contains:
- All user preferences (theme, streak, app settings)
- Sync metadata (last updated, sync status)
- Timestamps for conflict resolution

## Usage

### Basic Sync Operations

```dart
// Get the provider
final userSettings = Provider.of<UserSettingsProvider>(context, listen: false);

// Sync to Firebase
await userSettings.syncToFirebase();

// Sync from Firebase
await userSettings.syncFromFirebase();

// Force bidirectional sync
await userSettings.forceSync();
```

### Reverse Sync Integration

Settings are automatically synced when using the reverse sync service:

```dart
// When pulling from cloud, settings are included
final reverseSyncService = ReverseSyncService();
await reverseSyncService.syncDataFromFirebaseToHive();
// This will also sync settings from Firebase to local storage
```

### Updating Settings

```dart
// Update individual settings
await userSettings.setAppTheme('dark');
await userSettings.setStreakEnabled(true);
await userSettings.setAutoSaveEnabled(false);

// Update multiple settings at once
await userSettings.updateMultipleSettings({
  'appTheme': 'light',
  'dynamicColorsEnabled': true,
  'streakEnabled': false,
});
```

### Sync Status

```dart
// Check sync status
bool isInSync = userSettings.isInSync;
DateTime? lastSyncedAt = userSettings.lastSyncedAt;
DateTime? lastUpdated = userSettings.lastUpdated;
```

## Integration Points

### Main App
The `UserSettingsProvider` is automatically initialized in `main.dart` and available throughout the app.

### Settings UI
Settings sync options are available in the existing "Sync & Cloud" bottom sheet, accessible from the main settings page.

### Existing Providers
The service integrates with existing providers:
- `ThemeProvider` - for theme settings
- `StreakProvider` - for streak settings
- `SyncSettingsProvider` - for sync preferences

### Cloud Sync Integration
Settings sync automatically respects the global cloud sync setting:
- When cloud sync is **enabled**: Settings sync normally to/from Firebase
- When cloud sync is **disabled**: Settings sync operations are blocked with user-friendly error messages
- Settings are included in reverse sync operations when pulling from cloud

## Migration

The service automatically handles migration from existing SharedPreferences:
1. Detects existing settings
2. Creates new `UserSettingsModel` instances
3. Syncs to Firebase on first use
4. Maintains backward compatibility

## Error Handling

- All operations include comprehensive error handling
- Errors are logged to Firebase Crashlytics
- User-friendly error messages via SnackBar
- Graceful fallback to local storage on sync failures

## Performance

- Lazy loading of settings
- Efficient batch operations
- Minimal network calls
- Local caching for offline use

## Security

- Settings are stored per-user in Firebase
- Authentication required for all operations
- Secure access through Firebase Auth rules

## Future Enhancements

- Real-time sync using Firebase streams
- Advanced conflict resolution strategies
- Settings backup/restore functionality
- Cross-platform settings migration
- Settings analytics and insights
