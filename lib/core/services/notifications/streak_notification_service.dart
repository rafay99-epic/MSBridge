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

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

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

  static Future<bool> areExactAlarmsPermitted() async {
    try {
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> evaluateAndScheduleAll({
    required bool notificationsEnabled,
    required bool dailyReminders,
    required bool urgentReminders,
    required TimeOfDay dailyTime,
    required bool soundEnabled,
    required bool vibrationEnabled,
    required bool isStreakAboutToEnd,
  }) async {
    try {
      await initialize();

      if (!notificationsEnabled) {
        await cancelAllNotifications();
        return;
      }

      if (dailyReminders) {
        await scheduleDailyReminder(
          time: dailyTime,
          enabled: true,
          soundEnabled: soundEnabled,
          vibrationEnabled: vibrationEnabled,
        );
      } else {
        await cancelDailyReminder();
      }

      if (urgentReminders && isStreakAboutToEnd) {
        await scheduleStreakEndingReminder(
          soundEnabled: soundEnabled,
          vibrationEnabled: vibrationEnabled,
        );
      } else {
        await cancelStreakEndingReminder();
      }
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Failed to evaluate/schedule streak notifications',
      );
    }
  }

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
      if (!await areNotificationsEnabled()) {
        debugPrint(
            'Daily reminder skipped: notification permission not granted');
        return;
      }
      await initialize();

      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

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
        icon: '@mipmap/launcher_icon',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        color: Color(0xFF7AA2F7),
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

      try {
        await _notificationsPlugin.zonedSchedule(
          _dailyReminderId.hashCode,
          '🔥 Keep Your Streak Alive!',
          'Create a note today to maintain your amazing streak!',
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint(
            'Daily streak reminder scheduled for ${time.hour}:${time.minute}');
      } catch (exactError) {
        if (exactError.toString().contains('exact_alarms_not_permitted')) {
          await _notificationsPlugin.zonedSchedule(
            _dailyReminderId.hashCode,
            '🔥 Keep Your Streak Alive!',
            'Create a note today to maintain your amazing streak!',
            tz.TZDateTime.from(scheduledDate, tz.local),
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          debugPrint(
              'Daily streak reminder scheduled (inexact) for ${time.hour}:${time.minute}');
        } else {
          rethrow;
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

  static Future<void> scheduleStreakEndingReminder({
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    try {
      if (!await areNotificationsEnabled()) {
        debugPrint(
            'Urgent reminder skipped: notification permission not granted');
        return;
      }
      await initialize();

      final now = DateTime.now();
      final eightPmToday = DateTime(now.year, now.month, now.day, 20, 0);
      var scheduledDate = now.isBefore(eightPmToday)
          ? eightPmToday
          : now.add(const Duration(minutes: 5));

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'streak_ending_reminder',
        'Streak Ending Alert',
        channelDescription: 'Urgent alerts when streak is about to end',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: vibrationEnabled,
        playSound: soundEnabled,
        icon: '@mipmap/ic_stat_msbridge',
        largeIcon:
            const DrawableResourceAndroidBitmap('@mipmap/ic_stat_msbridge'),
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

      try {
        await _notificationsPlugin.zonedSchedule(
          _streakEndingId.hashCode,
          '⚠️ Your Streak is About to End!',
          'Create a note today to save your streak before midnight!',
          tz.TZDateTime.from(scheduledDate, tz.local),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint(
            'Streak ending reminder scheduled for ${scheduledDate.toLocal()}');
      } catch (exactError) {
        if (exactError.toString().contains('exact_alarms_not_permitted')) {
          await _notificationsPlugin.zonedSchedule(
            _streakEndingId.hashCode,
            '⚠️ Your Streak is About to End!',
            'Create a note today to save your streak before midnight!',
            tz.TZDateTime.from(scheduledDate, tz.local),
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexact,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          debugPrint(
              'Streak ending reminder scheduled (inexact) for ${scheduledDate.toLocal()}');
        } else {
          rethrow;
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

  static Future<void> showImmediateStreakEndingReminder({
    bool soundEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    try {
      if (!await areNotificationsEnabled()) {
        debugPrint('Immediate urgent reminder skipped: permission not granted');
        return;
      }
      await initialize();

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'streak_ending_reminder',
        'Streak Ending Alert',
        channelDescription: 'Urgent alerts when streak is about to end',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: vibrationEnabled,
        playSound: soundEnabled,
        icon: '@mipmap/launcher_icon',
        color: const Color(0xFFFF7043),
        category: AndroidNotificationCategory.alarm,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        '⚠️ Your Streak is About to End!',
        'Create a note today to save your streak before midnight!',
        details,
      );

      debugPrint('Immediate streak ending reminder shown');
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'Failed to show immediate streak ending reminder',
      );
    }
  }

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
        icon: '@mipmap/launcher_icon',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/launcher_icon'),
        color: const Color(0xFF4CAF50),
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

  static Map<String, String> getNotificationTimingOptions() {
    return {
      '9:00 AM': 'Morning motivation',
      '12:00 PM': 'Lunch break reminder',
      '6:00 PM': 'Evening check-in',
      '9:00 PM': 'End of day reminder',
    };
  }

  static Future<void> setCustomNotificationTime(TimeOfDay time) async {
    try {
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

  static void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('Notification tapped: ${response.payload}');
    } catch (e, stackTrace) {
      FirebaseCrashlytics.instance.recordError(
        e,
        stackTrace,
        reason: 'Failed to handle notification tap',
        information: ['Payload: ${response.payload}'],
      );
    }
  }

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
