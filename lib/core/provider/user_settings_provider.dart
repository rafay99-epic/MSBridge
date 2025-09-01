import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/core/models/user_settings_model.dart';
import 'package:msbridge/core/repo/user_settings_repo.dart';

class UserSettingsProvider extends ChangeNotifier {
  final UserSettingsRepo _repo = UserSettingsRepo();

  UserSettingsModel? _settings;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Getters
  UserSettingsModel? get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  // Convenience getters for specific settings
  String get appTheme => _settings?.appTheme ?? 'dark';
  bool get dynamicColorsEnabled => _settings?.dynamicColorsEnabled ?? false;
  bool get streakEnabled => _settings?.streakEnabled ?? false;
  bool get notificationsEnabled => _settings?.notificationsEnabled ?? false;
  String get notificationTime => _settings?.notificationTime ?? '09:00';
  bool get milestoneNotifications => _settings?.milestoneNotifications ?? false;
  bool get urgentReminders => _settings?.urgentReminders ?? false;
  bool get dailyReminders => _settings?.dailyReminders ?? false;
  bool get soundEnabled => _settings?.soundEnabled ?? true;
  bool get vibrationEnabled => _settings?.vibrationEnabled ?? true;
  bool get autoSaveEnabled => _settings?.autoSaveEnabled ?? true;
  bool get fingerprintEnabled => _settings?.fingerprintEnabled ?? false;
  bool get cloudSyncEnabled => _settings?.cloudSyncEnabled ?? true;
  bool get versionHistoryEnabled => _settings?.versionHistoryEnabled ?? true;
  String get selectedAIModel => _settings?.selectedAIModel ?? 'gpt-3.5-turbo';

  UserSettingsProvider() {
    _initialize();
  }

  // Initialize the provider
  Future<void> _initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      _settings = await _repo.getOrCreateSettings();
      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh settings from local storage
  Future<void> refreshSettings() async {
    _setLoading(true);
    _clearError();

    try {
      _settings = await _repo.getOrCreateSettings();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sync settings to Firebase
  Future<bool> syncToFirebase() async {
    if (_settings == null) return false;

    // Check if cloud sync is enabled
    if (!cloudSyncEnabled) {
      _setError(
          'Cloud sync is disabled. Enable it in settings to sync to Firebase.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success = await _repo.syncToFirebase(_settings!);
      if (success) {
        // Update local settings with sync metadata
        _settings = _settings!.copyWith(
          isSynced: true,
          lastSyncedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to sync settings to Firebase: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sync settings from Firebase
  Future<bool> syncFromFirebase() async {
    // Check if cloud sync is enabled
    if (!cloudSyncEnabled) {
      _setError(
          'Cloud sync is disabled. Enable it in settings to sync from Firebase.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success = await _repo.syncFromFirebase();
      if (success) {
        await refreshSettings();
      }
      return success;
    } catch (e) {
      _setError('Failed to sync settings from Firebase: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update a specific setting
  Future<bool> updateSetting<T>(String settingKey, T value) async {
    if (_settings == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final success = await _repo.updateSetting(settingKey, value);
      if (success) {
        // Refresh settings to get the updated values
        await refreshSettings();
      }
      return success;
    } catch (e) {
      _setError('Failed to update setting: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update multiple settings at once
  Future<bool> updateMultipleSettings(Map<String, dynamic> updates) async {
    if (_settings == null) return false;

    _setLoading(true);
    _clearError();

    try {
      bool allSuccess = true;

      for (final entry in updates.entries) {
        final success = await _repo.updateSetting(entry.key, entry.value);
        if (!success) {
          allSuccess = false;
          break;
        }
      }

      if (allSuccess) {
        // Refresh settings to get all updated values
        await refreshSettings();
      }

      return allSuccess;
    } catch (e) {
      _setError('Failed to update multiple settings: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Export settings for backup
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      return await _repo.exportSettings();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to export settings: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to export settings: $e',
      );
      return {};
    }
  }

  // Import settings from backup
  Future<bool> importSettings(Map<String, dynamic> backupData) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _repo.importSettings(backupData);
      if (success) {
        await refreshSettings();
      }
      return success;
    } catch (e) {
      _setError('Failed to import settings: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset settings to default
  Future<bool> resetToDefault() async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _repo.resetToDefault();
      if (success) {
        await refreshSettings();
      }
      return success;
    } catch (e) {
      _setError('Failed to reset settings: $e');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Force sync all settings (useful for initial setup)
  Future<bool> forceSync() async {
    if (_settings == null) return false;

    // Check if cloud sync is enabled
    if (!cloudSyncEnabled) {
      _setError(
          'Cloud sync is disabled. Enable it in settings to sync with Firebase.');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // First sync to Firebase
      final syncSuccess = await _repo.syncToFirebase(_settings!);
      if (!syncSuccess) {
        _setError('Failed to sync settings to Firebase');
        return false;
      }

      // Then refresh from Firebase to ensure consistency
      final refreshSuccess = await _repo.syncFromFirebase();
      if (refreshSuccess) {
        await refreshSettings();
      }

      return refreshSuccess;
    } catch (e) {
      _setError('Failed to force sync settings: $e');

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if settings are in sync
  bool get isInSync => _settings?.isSynced ?? false;

  // Get last sync time
  DateTime? get lastSyncedAt => _settings?.lastSyncedAt;

  // Get last updated time
  DateTime? get lastUpdated => _settings?.lastUpdated;

  // Helper methods for specific setting updates
  Future<bool> setAppTheme(String theme) => updateSetting('appTheme', theme);
  Future<bool> setDynamicColors(bool enabled) =>
      updateSetting('dynamicColorsEnabled', enabled);
  Future<bool> setStreakEnabled(bool enabled) =>
      updateSetting('streakEnabled', enabled);
  Future<bool> setNotificationsEnabled(bool enabled) =>
      updateSetting('notificationsEnabled', enabled);
  Future<bool> setNotificationTime(String time) =>
      updateSetting('notificationTime', time);
  Future<bool> setMilestoneNotifications(bool enabled) =>
      updateSetting('milestoneNotifications', enabled);
  Future<bool> setUrgentReminders(bool enabled) =>
      updateSetting('urgentReminders', enabled);
  Future<bool> setDailyReminders(bool enabled) =>
      updateSetting('dailyReminders', enabled);
  Future<bool> setSoundEnabled(bool enabled) =>
      updateSetting('soundEnabled', enabled);
  Future<bool> setVibrationEnabled(bool enabled) =>
      updateSetting('vibrationEnabled', enabled);
  Future<bool> setAutoSaveEnabled(bool enabled) =>
      updateSetting('autoSaveEnabled', enabled);
  Future<bool> setFingerprintEnabled(bool enabled) =>
      updateSetting('fingerprintEnabled', enabled);
  Future<bool> setCloudSyncEnabled(bool enabled) =>
      updateSetting('cloudSyncEnabled', enabled);
  Future<bool> setVersionHistoryEnabled(bool enabled) =>
      updateSetting('versionHistoryEnabled', enabled);
  Future<bool> setSelectedAIModel(String model) =>
      updateSetting('selectedAIModel', model);

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    FlutterBugfender.sendCrash(
        'Failed to set error: $error', StackTrace.current.toString());
    FlutterBugfender.error(
      'Failed to set error: $error',
    );
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
