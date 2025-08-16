import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/core/models/streak_settings_model.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class StreakSettingsRepo {
  static const String _settingsKey = 'streak_settings_data';

  // Get current streak settings
  static Future<StreakSettingsModel> getStreakSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> data = json.decode(settingsJson);
        return StreakSettingsModel.fromJson(data);
      }
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to load streak settings',
      );
    }

    return StreakSettingsModel.defaultSettings();
  }

  // Save streak settings
  static Future<void> saveStreakSettings(StreakSettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = json.encode(settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to save streak settings',
        information: ['Settings: ${settings.toJson()}'],
      );
    }
  }

  // Update specific setting
  static Future<void> updateSetting<T>({
    required String settingKey,
    required T value,
  }) async {
    try {
      final currentSettings = await getStreakSettings();
      StreakSettingsModel updatedSettings;

      switch (settingKey) {
        case 'streakEnabled':
          updatedSettings =
              currentSettings.copyWith(streakEnabled: value as bool);
          break;
        case 'notificationsEnabled':
          updatedSettings =
              currentSettings.copyWith(notificationsEnabled: value as bool);
          break;
        case 'notificationTime':
          updatedSettings =
              currentSettings.copyWith(notificationTime: value as TimeOfDay);
          break;
        case 'milestoneNotifications':
          updatedSettings =
              currentSettings.copyWith(milestoneNotifications: value as bool);
          break;
        case 'urgentReminders':
          updatedSettings =
              currentSettings.copyWith(urgentReminders: value as bool);
          break;
        case 'dailyReminders':
          updatedSettings =
              currentSettings.copyWith(dailyReminders: value as bool);
          break;
        case 'soundEnabled':
          updatedSettings =
              currentSettings.copyWith(soundEnabled: value as bool);
          break;
        case 'vibrationEnabled':
          updatedSettings =
              currentSettings.copyWith(vibrationEnabled: value as bool);
          break;
        default:
          throw ArgumentError('Unknown setting key: $settingKey');
      }

      await saveStreakSettings(updatedSettings);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to update streak setting',
        information: ['Setting: $settingKey', 'Value: $value'],
      );
    }
  }

  // Reset settings to default
  static Future<void> resetToDefault() async {
    try {
      final defaultSettings = StreakSettingsModel.defaultSettings();
      await saveStreakSettings(defaultSettings);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to reset streak settings to default',
      );
    }
  }

  // Check if streak feature is enabled
  static Future<bool> isStreakEnabled() async {
    try {
      final settings = await getStreakSettings();
      return settings.streakEnabled;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to check if streak is enabled',
      );
      return true; // Default to enabled if error
    }
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await getStreakSettings();
      return settings.notificationsEnabled &&
          settings.hasAnyNotificationsEnabled;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to check if notifications are enabled',
      );
      return false; // Default to disabled if error
    }
  }

  // Get notification time
  static Future<TimeOfDay> getNotificationTime() async {
    try {
      final settings = await getStreakSettings();
      return settings.notificationTime;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to get notification time',
      );
      return const TimeOfDay(hour: 21, minute: 0); // Default to 9 PM
    }
  }

  // Export settings for backup
  static Future<Map<String, dynamic>> exportSettings() async {
    try {
      final settings = await getStreakSettings();
      return {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'settings': settings.toJson(),
      };
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to export streak settings',
      );
      return {};
    }
  }

  // Import settings from backup
  static Future<bool> importSettings(Map<String, dynamic> backupData) async {
    try {
      if (backupData['settings'] != null) {
        final settings = StreakSettingsModel.fromJson(backupData['settings']);
        await saveStreakSettings(settings);
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to import streak settings',
        information: ['Backup data: $backupData'],
      );
      return false;
    }
  }
}
