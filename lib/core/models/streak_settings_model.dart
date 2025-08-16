import 'package:flutter/material.dart';

class StreakSettingsModel {
  final bool streakEnabled;
  final bool notificationsEnabled;
  final TimeOfDay notificationTime;
  final bool milestoneNotifications;
  final bool urgentReminders;
  final bool dailyReminders;
  final bool soundEnabled;
  final bool vibrationEnabled;

  StreakSettingsModel({
    required this.streakEnabled,
    required this.notificationsEnabled,
    required this.notificationTime,
    required this.milestoneNotifications,
    required this.urgentReminders,
    required this.dailyReminders,
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  factory StreakSettingsModel.defaultSettings() {
    return StreakSettingsModel(
      streakEnabled: true,
      notificationsEnabled: true,
      notificationTime: const TimeOfDay(hour: 21, minute: 0), // 9:00 PM
      milestoneNotifications: true,
      urgentReminders: true,
      dailyReminders: true,
      soundEnabled: true,
      vibrationEnabled: true,
    );
  }

  factory StreakSettingsModel.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['notificationTime'] ?? '21:00').split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return StreakSettingsModel(
      streakEnabled: json['streakEnabled'] ?? true,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      notificationTime: TimeOfDay(hour: hour, minute: minute),
      milestoneNotifications: json['milestoneNotifications'] ?? true,
      urgentReminders: json['urgentReminders'] ?? true,
      dailyReminders: json['dailyReminders'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streakEnabled': streakEnabled,
      'notificationsEnabled': notificationsEnabled,
      'notificationTime':
          '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}',
      'milestoneNotifications': milestoneNotifications,
      'urgentReminders': urgentReminders,
      'dailyReminders': dailyReminders,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  StreakSettingsModel copyWith({
    bool? streakEnabled,
    bool? notificationsEnabled,
    TimeOfDay? notificationTime,
    bool? milestoneNotifications,
    bool? urgentReminders,
    bool? dailyReminders,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return StreakSettingsModel(
      streakEnabled: streakEnabled ?? this.streakEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
      milestoneNotifications:
          milestoneNotifications ?? this.milestoneNotifications,
      urgentReminders: urgentReminders ?? this.urgentReminders,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  // Get notification timing options
  static Map<String, String> getNotificationTimingOptions() {
    return {
      '9:00 AM': 'Morning motivation',
      '12:00 PM': 'Lunch break reminder',
      '6:00 PM': 'Evening check-in',
      '9:00 PM': 'End of day reminder',
    };
  }

  // Convert string time to TimeOfDay
  static TimeOfDay timeFromString(String timeString) {
    final parts = timeString.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  // Convert TimeOfDay to string
  static String timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Check if any notifications are enabled
  bool get hasAnyNotificationsEnabled {
    return notificationsEnabled &&
        (dailyReminders || urgentReminders || milestoneNotifications);
  }

  // Get notification summary
  String get notificationSummary {
    if (!notificationsEnabled) return 'All notifications disabled';

    final enabledTypes = <String>[];
    if (dailyReminders) enabledTypes.add('Daily reminders');
    if (urgentReminders) enabledTypes.add('Urgent alerts');
    if (milestoneNotifications) enabledTypes.add('Milestone celebrations');

    if (enabledTypes.isEmpty) return 'No notification types enabled';

    return enabledTypes.join(', ');
  }
}
