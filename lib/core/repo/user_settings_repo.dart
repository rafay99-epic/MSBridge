import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/core/models/user_settings_model.dart';
import 'package:msbridge/core/repo/auth_repo.dart';

class UserSettingsRepo {
  static const String _settingsKey = 'user_settings';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepo _authRepo = AuthRepo();

  // Get current user ID
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

  // Load settings from SharedPreferences
  Future<UserSettingsModel?> loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        var model = UserSettingsModel.fromJson(settingsJson);
        final tplEnabled = prefs.getBool('templates_enabled');
        final tplCloud = prefs.getBool('templates_cloud_sync_enabled');
        final tplInterval = prefs.getInt('templates_sync_interval_minutes');
        model = model.copyWith(
          templatesEnabled: tplEnabled ?? model.templatesEnabled,
          templatesCloudSyncEnabled:
              tplCloud ?? model.templatesCloudSyncEnabled,
          templatesSyncIntervalMinutes:
              tplInterval ?? model.templatesSyncIntervalMinutes,
        );
        return model;
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to load local settings');
    }
    return null;
  }

  // Save settings to SharedPreferences
  Future<void> saveLocalSettings(UserSettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = settings.toJson();
      await prefs.setString(_settingsKey, settingsJson);
      // Also persist template settings for runtime consumers
      await prefs.setBool('templates_enabled', settings.templatesEnabled);
      await prefs.setBool(
          'templates_cloud_sync_enabled', settings.templatesCloudSyncEnabled);
      await prefs.setInt('templates_sync_interval_minutes',
          settings.templatesSyncIntervalMinutes);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to save local settings');
      rethrow;
    }
  }

  // Create default settings for a user
  Future<UserSettingsModel> createDefaultSettings(String userId) async {
    final defaultSettings = UserSettingsModel(
      userId: userId,
      lastUpdated: DateTime.now(),
      appTheme: 'dark',
      dynamicColorsEnabled: false,
      streakEnabled: false,
      notificationsEnabled: false,
      notificationTime: '09:00',
      milestoneNotifications: false,
      urgentReminders: false,
      dailyReminders: false,
      soundEnabled: true,
      vibrationEnabled: true,
      autoSaveEnabled: true,
      fingerprintEnabled: false,
      cloudSyncEnabled: true,
      versionHistoryEnabled: true,
      selectedAIModel: 'gpt-3.5-turbo',
      templatesEnabled: true,
      templatesCloudSyncEnabled: true,
      templatesSyncIntervalMinutes: 0,
    );

    await saveLocalSettings(defaultSettings);
    return defaultSettings;
  }

  // Sync settings to Firebase
  Future<bool> syncToFirebase(UserSettingsModel settings) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Update the settings document in the meta subcollection
      final userDoc = _firestore.collection('users').doc(userId);
      await userDoc.collection('meta').doc('settings').set({
        ...settings.toMap(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      // Mark as synced
      final updatedSettings = settings.copyWith(
        isSynced: true,
        lastSyncedAt: DateTime.now(),
      );
      await saveLocalSettings(updatedSettings);

      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync settings to Firebase');
      return false;
    }
  }

  // Load settings from Firebase
  Future<UserSettingsModel?> loadFromFirebase() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final settingsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('settings')
          .get();
      if (!settingsDoc.exists) {
        return null;
      }

      final data = settingsDoc.data();
      if (data == null) {
        return null;
      }

      return UserSettingsModel.fromMap(data);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to load settings from Firebase');
      return null;
    }
  }

  // Sync settings from Firebase to local
  Future<bool> syncFromFirebase() async {
    try {
      final cloudSettings = await loadFromFirebase();
      if (cloudSettings != null) {
        await saveLocalSettings(cloudSettings);
        return true;
      }
      return false;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to sync settings from Firebase');
      return false;
    }
  }

  // Get or create settings for current user
  Future<UserSettingsModel> getOrCreateSettings() async {
    try {
      // Try to load from local storage first
      var settings = await loadLocalSettings();

      if (settings == null) {
        // Try to load from Firebase
        settings = await loadFromFirebase();

        if (settings == null) {
          // Create default settings
          final userId = await _getCurrentUserId();
          if (userId == null) {
            throw Exception('User not authenticated');
          }
          settings = await createDefaultSettings(userId);
        }
      }

      return settings;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to get or create settings');
      rethrow;
    }
  }

  // Update a specific setting
  Future<bool> updateSetting<T>(String settingKey, T value) async {
    try {
      final currentSettings = await getOrCreateSettings();

      // Create updated settings with the new value
      final updatedSettings =
          _updateSettingValue(currentSettings, settingKey, value);

      // Save locally
      await saveLocalSettings(updatedSettings);

      // Only sync to Firebase if cloud sync is enabled
      if (updatedSettings.cloudSyncEnabled) {
        await syncToFirebase(updatedSettings);
      }

      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to update setting: $settingKey');
      return false;
    }
  }

  // Helper method to update specific setting values
  UserSettingsModel _updateSettingValue(
      UserSettingsModel settings, String key, dynamic value) {
    switch (key) {
      case 'appTheme':
        return settings.copyWith(appTheme: value as String);
      case 'dynamicColorsEnabled':
        return settings.copyWith(dynamicColorsEnabled: value as bool);
      case 'streakEnabled':
        return settings.copyWith(streakEnabled: value as bool);
      case 'notificationsEnabled':
        return settings.copyWith(notificationsEnabled: value as bool);
      case 'notificationTime':
        return settings.copyWith(notificationTime: value as String);
      case 'milestoneNotifications':
        return settings.copyWith(milestoneNotifications: value as bool);
      case 'urgentReminders':
        return settings.copyWith(urgentReminders: value as bool);
      case 'dailyReminders':
        return settings.copyWith(dailyReminders: value as bool);
      case 'soundEnabled':
        return settings.copyWith(soundEnabled: value as bool);
      case 'vibrationEnabled':
        return settings.copyWith(vibrationEnabled: value as bool);
      case 'autoSaveEnabled':
        return settings.copyWith(autoSaveEnabled: value as bool);
      case 'fingerprintEnabled':
        return settings.copyWith(fingerprintEnabled: value as bool);
      case 'cloudSyncEnabled':
        return settings.copyWith(cloudSyncEnabled: value as bool);
      case 'versionHistoryEnabled':
        return settings.copyWith(versionHistoryEnabled: value as bool);
      case 'selectedAIModel':
        return settings.copyWith(selectedAIModel: value as String);
      case 'templatesEnabled':
        return settings.copyWith(templatesEnabled: value as bool);
      case 'templatesCloudSyncEnabled':
        return settings.copyWith(templatesCloudSyncEnabled: value as bool);
      case 'templatesSyncIntervalMinutes':
        return settings.copyWith(templatesSyncIntervalMinutes: value as int);
      default:
        throw Exception('Unknown setting key: $key');
    }
  }

  // Export settings for backup
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      final settings = await getOrCreateSettings();
      return {
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': settings.toMap(),
      };
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to export settings');
      return {};
    }
  }

  // Import settings from backup
  Future<bool> importSettings(Map<String, dynamic> backupData) async {
    try {
      if (backupData['settings'] == null) {
        return false;
      }

      final settings = UserSettingsModel.fromMap(backupData['settings']);
      await saveLocalSettings(settings);

      // Only sync to Firebase if cloud sync is enabled
      if (settings.cloudSyncEnabled) {
        await syncToFirebase(settings);
      }

      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to import settings');
      return false;
    }
  }

  // Reset settings to default
  Future<bool> resetToDefault() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return false;
      }

      final defaultSettings = await createDefaultSettings(userId);

      // Only sync to Firebase if cloud sync is enabled
      if (defaultSettings.cloudSyncEnabled) {
        await syncToFirebase(defaultSettings);
      }

      return true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to reset settings to default');
      return false;
    }
  }
}
