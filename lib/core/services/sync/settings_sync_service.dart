// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Project imports:
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/user_settings_repo.dart';

class SettingsSyncService {
  final AuthRepo _authRepo = AuthRepo();
  final UserSettingsRepo _settingsRepo = UserSettingsRepo();

  // Sync all settings to Firebase
  Future<bool> syncSettingsToFirebase() async {
    try {
      final settings = await _settingsRepo.getOrCreateSettings();
      return await _settingsRepo.syncToFirebase(settings);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync settings to Firebase');
      return false;
    }
  }

  // Sync settings from Firebase to local
  Future<bool> syncSettingsFromFirebase() async {
    try {
      return await _settingsRepo.syncFromFirebase();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync settings from Firebase');
      return false;
    }
  }

  // Sync settings bidirectionally (merge strategy)
  Future<bool> syncSettingsBidirectional() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get local settings
      final localSettings = await _settingsRepo.getOrCreateSettings();

      // Get cloud settings
      final cloudSettings = await _settingsRepo.loadFromFirebase();

      if (cloudSettings == null) {
        // No cloud settings, just sync local to cloud
        return await _settingsRepo.syncToFirebase(localSettings);
      }

      // Compare timestamps to determine which is newer
      final localNewer =
          localSettings.lastUpdated.isAfter(cloudSettings.lastUpdated);
      final cloudNewer =
          cloudSettings.lastUpdated.isAfter(localSettings.lastUpdated);

      if (localNewer) {
        // Local is newer, sync to cloud
        return await _settingsRepo.syncToFirebase(localSettings);
      } else if (cloudNewer) {
        // Cloud is newer, sync to local
        final mergedSettings = cloudSettings.copyWith(
          isSynced: true,
          lastSyncedAt: DateTime.now(),
        );

        await _settingsRepo.saveLocalSettings(mergedSettings);
        return true;
      } else {
        return true;
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync settings bidirectionally');
      return false;
    }
  }

  // Sync specific setting categories
  Future<bool> syncThemeSettings() async {
    try {
      final settings = await _settingsRepo.getOrCreateSettings();
      final themeSettings = settings.copyWith(
        lastUpdated: DateTime.now(),
      );
      return await _settingsRepo.syncToFirebase(themeSettings);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync theme settings');
      return false;
    }
  }

  Future<bool> syncStreakSettings() async {
    try {
      final settings = await _settingsRepo.getOrCreateSettings();
      final streakSettings = settings.copyWith(
        lastUpdated: DateTime.now(),
      );
      return await _settingsRepo.syncToFirebase(streakSettings);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync streak settings');
      return false;
    }
  }

  Future<bool> syncAppSettings() async {
    try {
      final settings = await _settingsRepo.getOrCreateSettings();
      final appSettings = settings.copyWith(
        lastUpdated: DateTime.now(),
      );
      return await _settingsRepo.syncToFirebase(appSettings);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync app settings');
      return false;
    }
  }

  // Batch sync multiple settings
  Future<bool> batchSyncSettings(List<String> settingKeys) async {
    try {
      final settings = await _settingsRepo.getOrCreateSettings();
      final updatedSettings = settings.copyWith(
        lastUpdated: DateTime.now(),
      );
      return await _settingsRepo.syncToFirebase(updatedSettings);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to batch sync settings');
      return false;
    }
  }

  // Check if settings are in sync
  Future<bool> areSettingsInSync() async {
    try {
      final localSettings = await _settingsRepo.getOrCreateSettings();
      return localSettings.isSynced;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to check if settings are in sync');
      return false;
    }
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final localSettings = await _settingsRepo.getOrCreateSettings();
      return localSettings.lastSyncedAt;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to get last sync timestamp');
      return null;
    }
  }

  // Force sync all settings (useful for initial setup or conflict resolution)
  Future<bool> forceSyncAllSettings() async {
    try {
      final settings = await _settingsRepo.getOrCreateSettings();

      // First, sync to Firebase
      final syncSuccess = await _settingsRepo.syncToFirebase(settings);
      if (!syncSuccess) {
        return false;
      }

      // Then, refresh from Firebase to ensure consistency
      final refreshSuccess = await _settingsRepo.syncFromFirebase();
      return refreshSuccess;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to force sync all settings');
      return false;
    }
  }

  // Migrate existing SharedPreferences settings to the new system
  Future<bool> migrateExistingSettings() async {
    try {
      // This method would handle migrating existing SharedPreferences
      // settings to the new UserSettingsModel system
      // For now, we'll just create default settings

      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final defaultSettings = await _settingsRepo.createDefaultSettings(userId);
      return await _settingsRepo.syncToFirebase(defaultSettings);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to migrate existing settings');
      return false;
    }
  }

  // Get sync status summary
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final localSettings = await _settingsRepo.getOrCreateSettings();
      final lastSync = localSettings.lastSyncedAt;
      final isInSync = localSettings.isSynced;
      final lastUpdated = localSettings.lastUpdated;

      return {
        'isInSync': isInSync,
        'lastSyncedAt': lastSync?.toIso8601String(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'syncStatus': isInSync ? 'synced' : 'pending',
        'userId': localSettings.userId,
        'firebasePath': 'users/${localSettings.userId}/meta/settings',
      };
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to get sync status');
      return {
        'isInSync': false,
        'lastSyncedAt': null,
        'lastUpdated': null,
        'syncStatus': 'error',
        'userId': null,
        'firebasePath': null,
      };
    }
  }

  // Helper method to get current user ID
  Future<String?> _getCurrentUserId() async {
    try {
      final authResult = await _authRepo.getCurrentUser();
      return authResult.user?.uid;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to get current user ID for settings sync');
      return null;
    }
  }

  // Clean up old settings data (if needed)
  Future<bool> cleanupOldSettings() async {
    try {
      // This method could be used to clean up old SharedPreferences
      // keys that are no longer needed after migration
      // For now, we'll just return true
      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to cleanup old settings');
      return false;
    }
  }
}
