import 'package:flutter/material.dart';
import 'package:msbridge/core/models/streak_model.dart';
import 'package:msbridge/core/models/streak_settings_model.dart';
import 'package:msbridge/core/repo/streak_repo.dart';
import 'package:msbridge/core/repo/streak_settings_repo.dart';
import 'package:msbridge/core/services/notifications/streak_notification_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:msbridge/core/services/sync/streak_sync_service.dart';

class StreakProvider extends ChangeNotifier {
  StreakModel _currentStreak = StreakModel.initial();
  StreakSettingsModel _settings = StreakSettingsModel.defaultSettings();
  bool _isLoading = false;
  bool _isInitialized = false;

  // Getters
  StreakModel get currentStreak => _currentStreak;
  StreakSettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Computed getters
  int get currentStreakCount => _currentStreak.currentStreak;
  int get longestStreakCount => _currentStreak.longestStreak;
  bool get isStreakAboutToEnd => _currentStreak.isStreakAboutToEnd;
  bool get hasStreakEnded => _currentStreak.hasStreakEnded;
  int get daysUntilStreakEnds => _currentStreak.daysUntilStreakEnds;

  // Settings getters
  bool get streakEnabled => _settings.streakEnabled;
  bool get notificationsEnabled => _settings.notificationsEnabled;
  TimeOfDay get notificationTime => _settings.notificationTime;
  bool get milestoneNotifications => _settings.milestoneNotifications;
  bool get urgentReminders => _settings.urgentReminders;
  bool get dailyReminders => _settings.dailyReminders;

  StreakProvider() {
    initializeStreak();
  }

  // Initialize streak data and settings
  Future<void> initializeStreak() async {
    if (_isInitialized) return;

    _setLoading(true);
    try {
      // Load streak data
      _currentStreak = await StreakRepo.getStreakData();

      // Load settings
      _settings = await StreakSettingsRepo.getStreakSettings();

      // Initialize notifications if enabled
      if (_settings.notificationsEnabled &&
          _settings.hasAnyNotificationsEnabled) {
        await _initializeNotifications();
      }

      _isInitialized = true;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to initialize streak provider',
      );
      debugPrint('Error initializing streak: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Initialize notifications based on settings
  Future<void> _initializeNotifications() async {
    try {
      if (_settings.dailyReminders) {
        await StreakNotificationService.scheduleDailyReminder(
          time: _settings.notificationTime,
          enabled: _settings.notificationsEnabled,
          soundEnabled: _settings.soundEnabled,
          vibrationEnabled: _settings.vibrationEnabled,
        );
      }

      if (_settings.urgentReminders && _currentStreak.isStreakAboutToEnd) {
        await StreakNotificationService.scheduleStreakEndingReminder(
          soundEnabled: _settings.soundEnabled,
          vibrationEnabled: _settings.vibrationEnabled,
        );
      }
    } catch (e, stackTrace) {
      // Log error but don't crash the app
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to initialize notifications',
      );
      debugPrint('Notification initialization failed: $e');
      // Continue without notifications rather than crashing
    }
  }

  // Update streak when user creates a note
  Future<void> updateStreakOnActivity() async {
    if (!_settings.streakEnabled) return;

    try {
      final updatedStreak = await StreakRepo.updateStreakOnActivity();
      _currentStreak = updatedStreak;
      notifyListeners();

      // Show success message for streak milestones
      _showStreakMilestoneMessage(updatedStreak);

      // Update notifications if needed
      if (_settings.notificationsEnabled) {
        await _updateNotifications();
      }

      // Immediately sync streak changes to cloud (respects toggles)
      try {
        await StreakSyncService().pushLocalToCloud();
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'Failed to sync streak to cloud: $e',
        );
        // non-fatal; already logged inside service
      }
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to update streak on activity',
        information: [
          'Streak enabled: $_settings.streakEnabled',
          'Notifications enabled: $_settings.notificationsEnabled',
          'Current streak before update: ${_currentStreak.currentStreak}',
        ],
      );
    }
  }

  // Update notifications based on current streak state
  Future<void> _updateNotifications() async {
    try {
      if (_settings.dailyReminders) {
        await StreakNotificationService.scheduleDailyReminder(
          time: _settings.notificationTime,
          enabled: _settings.notificationsEnabled,
          soundEnabled: _settings.soundEnabled,
          vibrationEnabled: _settings.vibrationEnabled,
        );
      }

      if (_settings.urgentReminders && _currentStreak.isStreakAboutToEnd) {
        await StreakNotificationService.scheduleStreakEndingReminder(
          soundEnabled: _settings.soundEnabled,
          vibrationEnabled: _settings.vibrationEnabled,
        );
      }
    } catch (e, stackTrace) {
      // Log error but don't crash the app
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to update notifications',
      );
      debugPrint('Notification update failed: $e');
      // Continue without notifications rather than crashing
    }
  }

  // Show streak milestone messages
  void _showStreakMilestoneMessage(StreakModel streak) {
    if (!_settings.milestoneNotifications) return;

    try {
      if (streak.currentStreak == 1 &&
          streak.currentStreak > streak.longestStreak) {
        // First streak
        _showStreakMessage("🎉 Welcome to your streak journey! Keep it going!");
      } else if (streak.currentStreak == 7) {
        // Week milestone
        _showStreakMessage("🔥 Amazing! You've maintained a 7-day streak!");
        _showMilestoneNotification("7-Day Streak!",
            "🔥 Amazing! You've maintained a 7-day streak!", 7);
      } else if (streak.currentStreak == 30) {
        // Month milestone
        _showStreakMessage("🌟 Incredible! 30 days of consistency!");
        _showMilestoneNotification(
            "30-Day Streak!", "🌟 Incredible! 30 days of consistency!", 30);
      } else if (streak.currentStreak == 100) {
        // Century milestone
        _showStreakMessage("💎 Legendary! 100 days of dedication!");
        _showMilestoneNotification(
            "100-Day Streak!", "💎 Legendary! 100 days of dedication!", 100);
      }
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to show streak milestone message',
      );
    }
  }

  void _showStreakMessage(String message) {
    // This will be implemented to show messages in the UI
    // For now, we'll just print to console
    debugPrint(message);
  }

  Future<void> _showMilestoneNotification(
      String title, String body, int streakCount) async {
    try {
      if (_settings.milestoneNotifications) {
        await StreakNotificationService.showMilestoneNotification(
          title: title,
          body: body,
          streakCount: streakCount,
          soundEnabled: _settings.soundEnabled,
          vibrationEnabled: _settings.vibrationEnabled,
        );
      }
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to show milestone notification',
      );
    }
  }

  // Update settings
  Future<void> updateSetting<T>(String settingKey, T value) async {
    try {
      await StreakSettingsRepo.updateSetting(
        settingKey: settingKey,
        value: value,
      );

      // Reload settings
      _settings = await StreakSettingsRepo.getStreakSettings();

      // Update notifications if needed
      if (settingKey.startsWith('notification') ||
          settingKey == 'notificationsEnabled') {
        await _updateNotifications();
      }

      notifyListeners();
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to update streak setting',
        information: ['Setting: $settingKey', 'Value: $value'],
      );
      debugPrint('Error updating setting $settingKey: $e');
    }
  }

  // Enable/disable streak feature
  Future<void> setStreakEnabled(bool enabled) async {
    await updateSetting('streakEnabled', enabled);

    if (!enabled) {
      // Clear streak data when disabling
      await StreakRepo.resetStreak();
      _currentStreak = StreakModel.initial();
      notifyListeners();
    }
  }

  // Enable/disable notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    await updateSetting('notificationsEnabled', enabled);

    if (!enabled) {
      await StreakNotificationService.cancelAllNotifications();
    } else {
      await _initializeNotifications();
    }
  }

  // Set notification time
  Future<void> setNotificationTime(TimeOfDay time) async {
    await updateSetting('notificationTime', time);

    if (_settings.dailyReminders) {
      await StreakNotificationService.scheduleDailyReminder(
        time: time,
        enabled: _settings.notificationsEnabled,
        soundEnabled: _settings.soundEnabled,
        vibrationEnabled: _settings.vibrationEnabled,
      );
    }
  }

  // Reset streak (for testing or user preference)
  Future<void> resetStreak() async {
    try {
      await StreakRepo.resetStreak();
      _currentStreak = StreakModel.initial();
      notifyListeners();
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to reset streak',
      );
    }
  }

  // Reset settings to default
  Future<void> resetSettings() async {
    try {
      await StreakSettingsRepo.resetToDefault();
      _settings = StreakSettingsModel.defaultSettings();

      // Reinitialize notifications
      if (_settings.notificationsEnabled) {
        await _initializeNotifications();
      }

      notifyListeners();
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to reset streak settings',
      );
    }
  }

  // Refresh streak data from local storage and notify UI
  Future<void> refreshStreak() async {
    _setLoading(true);
    try {
      _currentStreak = await StreakRepo.getStreakData();
      // keep settings as-is
      notifyListeners();
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to refresh streak from storage',
      );
    } finally {
      _setLoading(false);
    }
  }

  // Check if streak needs attention
  bool get needsAttention {
    return _currentStreak.isStreakAboutToEnd || _currentStreak.hasStreakEnded;
  }

  // Get motivational message based on streak status
  String get motivationalMessage {
    if (!_settings.streakEnabled) {
      return "Streak feature is disabled";
    }

    if (_currentStreak.currentStreak == 0) {
      return "Start your streak today by creating a note!";
    } else if (_currentStreak.isStreakAboutToEnd) {
      return "⚠️ Your streak is about to end! Create a note today to keep it alive!";
    } else if (_currentStreak.hasStreakEnded) {
      return "💔 Your streak has ended. Start a new one today!";
    } else {
      return "🔥 Keep up the great work! Your ${_currentStreak.currentStreak}-day streak is amazing!";
    }
  }

  // Export settings
  Future<Map<String, dynamic>> exportSettings() async {
    try {
      return await StreakSettingsRepo.exportSettings();
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to export streak settings',
      );
      return {};
    }
  }

  // Import settings
  Future<bool> importSettings(Map<String, dynamic> backupData) async {
    try {
      final success = await StreakSettingsRepo.importSettings(backupData);
      if (success) {
        _settings = await StreakSettingsRepo.getStreakSettings();
        notifyListeners();
      }
      return success;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to import streak settings',
      );
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
