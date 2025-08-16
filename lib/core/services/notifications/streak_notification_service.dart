import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:msbridge/core/permissions/notification_permission.dart';

class StreakNotificationService {
  static const String _dailyReminderId = 'streak_daily_reminder';
  static const String _streakEndingId = 'streak_ending_reminder';
  static const String _streakMilestoneId = 'streak_milestone';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  // Initialize notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to initialize streak notifications',
      );
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      await initialize();
      return await NotificationPermissionHandler
          .isNotificationPermissionGranted();
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to check notification status',
      );
      return false;
    }
  }

  // Request notification permission
  static Future<bool> requestPermission(BuildContext context) async {
    try {
      return await NotificationPermissionHandler
          .checkAndRequestNotificationPermission(context);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to request notification permission',
      );
      return false;
    }
  }

  // Check if exact alarms are permitted (Android 12+)
  static Future<bool> areExactAlarmsPermitted() async {
    try {
      // For Android 12+, exact alarms require special permission
      // We'll handle this gracefully by falling back to inexact scheduling
      return false; // Assume inexact for now, handle errors gracefully
    } catch (e) {
      return false;
    }
  }

  // Schedule daily reminder notification
  static Future<void> scheduleDailyReminder({
    required TimeOfDay time,
    required bool enabled,
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    if (!enabled) {
      await cancelDailyReminder();
      return;
    }

    try {
      await initialize();

      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'streak_daily_reminder',
        'Streak Daily Reminder',
        channelDescription: 'Daily reminders to maintain your streak',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: vibrationEnabled,
        playSound: soundEnabled,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF7AA2F7), // Your app's secondary color
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Try exact scheduling first, fallback to inexact if permission denied
      try {
        await _notificationsPlugin.zonedSchedule(
          _dailyReminderId.hashCode,
          '🔥 Keep Your Streak Alive!',
          'Create a note today to maintain your amazing streak!',
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint(
            'Daily streak reminder scheduled for ${time.hour}:${time.minute}');
      } catch (exactError) {
        // Fallback to inexact scheduling if exact alarms not permitted
        if (exactError.toString().contains('exact_alarms_not_permitted')) {
          await _notificationsPlugin.zonedSchedule(
            _dailyReminderId.hashCode,
            '🔥 Keep Your Streak Alive!',
            'Create a note today to maintain your amazing streak!',
            tz.TZDateTime.from(scheduledDate, tz.local),
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          debugPrint(
              'Daily streak reminder scheduled (inexact) for ${time.hour}:${time.minute}');
        } else {
          rethrow; // Re-throw if it's a different error
        }
      }
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to schedule daily reminder',
        information: ['Time: ${time.hour}:${time.minute}', 'Enabled: $enabled'],
      );
      debugPrint('Failed to schedule daily reminder: $e');
    }
  }

  // Schedule urgent reminder when streak is about to end
  static Future<void> scheduleStreakEndingReminder({
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    try {
      await initialize();

      // Schedule for 8 PM same day if not already passed
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        20, // 8 PM
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'streak_ending_reminder',
        'Streak Ending Alert',
        channelDescription: 'Urgent alerts when streak is about to end',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: vibrationEnabled,
        playSound: soundEnabled,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFFF7043), // Warning color
        category: AndroidNotificationCategory.alarm,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Try exact scheduling first, fallback to inexact if permission denied
      try {
        await _notificationsPlugin.zonedSchedule(
          _streakEndingId.hashCode,
          '⚠️ Your Streak is About to End!',
          'Create a note today to save your streak before midnight!',
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('Streak ending reminder scheduled for 8 PM');
      } catch (exactError) {
        // Fallback to inexact scheduling if exact alarms not permitted
        if (exactError.toString().contains('exact_alarms_not_permitted')) {
          await _notificationsPlugin.zonedSchedule(
            _streakEndingId.hashCode,
            '⚠️ Your Streak is About to End!',
            'Create a note today to save your streak before midnight!',
            tz.TZDateTime.from(scheduledDate, tz.local),
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
          debugPrint('Streak ending reminder scheduled (inexact) for 8 PM');
        } else {
          rethrow; // Re-throw if it's a different error
        }
      }
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to schedule streak ending reminder',
      );
      debugPrint('Failed to schedule streak ending reminder: $e');
    }
  }

  // Show milestone notification
  static Future<void> showMilestoneNotification({
    required String title,
    required String body,
    required int streakCount,
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    try {
      await initialize();

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'streak_milestone',
        'Streak Milestone',
        channelDescription: 'Celebrations for streak milestones',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: vibrationEnabled,
        playSound: soundEnabled,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF4CAF50), // Success color
        category: AndroidNotificationCategory.status,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notificationsPlugin.show(
        _streakMilestoneId.hashCode + streakCount,
        title,
        body,
        notificationDetails,
      );

      debugPrint('Milestone notification shown: $title');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to show milestone notification',
        information: ['Title: $title', 'Streak: $streakCount'],
      );
      debugPrint('Failed to show milestone notification: $e');
    }
  }

  // Cancel daily reminder
  static Future<void> cancelDailyReminder() async {
    try {
      await _notificationsPlugin.cancel(_dailyReminderId.hashCode);
      debugPrint('Daily streak reminder cancelled');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to cancel daily reminder',
      );
      debugPrint('Failed to cancel daily reminder: $e');
    }
  }

  // Cancel streak ending reminder
  static Future<void> cancelStreakEndingReminder() async {
    try {
      await _notificationsPlugin.cancel(_streakEndingId.hashCode);
      debugPrint('Streak ending reminder cancelled');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to cancel streak ending reminder',
      );
      debugPrint('Failed to cancel streak ending reminder: $e');
    }
  }

  // Cancel all streak notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await cancelDailyReminder();
      await cancelStreakEndingReminder();
      await _notificationsPlugin.cancelAll();
      debugPrint('All streak notifications cancelled');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to cancel all notifications',
      );
      debugPrint('Failed to cancel all notifications: $e');
    }
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

  // Set custom notification time
  static Future<void> setCustomNotificationTime(TimeOfDay time) async {
    try {
      // This would be called from settings to update notification time
      debugPrint(
          'Custom notification time set to: ${time.hour}:${time.minute}');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to set custom notification time',
        information: ['Time: ${time.hour}:${time.minute}'],
      );
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    try {
      // Navigate to appropriate screen based on notification type
      debugPrint('Notification tapped: ${response.payload}');

      // You can implement navigation logic here
      // For example, navigate to note creation screen
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to handle notification tap',
        information: ['Payload: ${response.payload}'],
      );
    }
  }

  // Check if notification is scheduled
  static Future<bool> isDailyReminderScheduled() async {
    try {
      final pendingNotifications =
          await _notificationsPlugin.pendingNotificationRequests();
      return pendingNotifications
          .any((notification) => notification.id == _dailyReminderId.hashCode);
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to check if daily reminder is scheduled',
      );
      return false;
    }
  }
}
