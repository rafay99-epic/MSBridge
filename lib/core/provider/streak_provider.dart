import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/core/models/streak_model.dart';
import 'package:msbridge/core/models/streak_settings_model.dart';
import 'package:msbridge/core/repo/streak_repo.dart';
import 'package:msbridge/core/repo/streak_settings_repo.dart';
import 'package:msbridge/core/services/notifications/streak_notification_service.dart';
import 'package:msbridge/core/services/telemetry/telemetry.dart';
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
    } catch (e, s) {
      FlutterBugfender.error('Failed to initialize streak provider: $e');
      FlutterBugfender.log('stack: $s');
      FlutterBugfender.sendCrash(
          'Failed to initialize streak provider: $e', s.toString());
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
    } catch (e) {
      // Log error but don't crash the app
      FlutterBugfender.sendCrash('Failed to initialize notifications: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to initialize notifications: $e',
      );
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
        FlutterBugfender.sendCrash('Failed to sync streak to cloud: $e',
            StackTrace.current.toString());
        FlutterBugfender.error(
          'Failed to sync streak to cloud: $e',
        );
      }

      // touch activity for adaptive scheduling
      await Telemetry.touchLastActivity();
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to update streak on activity: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to update streak on activity: $e',
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
    } catch (e) {
      // Log error but don't crash the app
      FlutterBugfender.sendCrash(
          'Failed to update notifications: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to update notifications: $e',
      );
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
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to show streak milestone message: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to show streak milestone message: $e',
      );
    }
  }

  void _showStreakMessage(String message) {
    // This will be implemented to show messages in the UI
    // For now, we'll just print to console
    FlutterBugfender.sendCrash('Failed to show streak message: $message',
        StackTrace.current.toString());
    FlutterBugfender.error(
      'Failed to show streak message: $message',
    );
    FlutterBugfender.log('Streak message: $message');
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
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to show milestone notification: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to show milestone notification: $e',
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
    } catch (e) {
      FlutterBugfender.sendCrash('Error updating setting $settingKey: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Error updating setting $settingKey: $e',
      );
      FlutterBugfender.log('Error updating setting $settingKey: $e');
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
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to reset streak: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to reset streak: $e',
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
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to reset streak settings: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to reset streak settings: $e',
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
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to refresh streak from storage: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to refresh streak from storage: $e',
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
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to export streak settings: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to export streak settings: $e',
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
    } catch (e) {
      FlutterBugfender.sendCrash('Failed to import streak settings: $e',
          StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to import streak settings: $e',
      );
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
