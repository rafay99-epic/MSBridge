// Dart imports:
import 'dart:async';

// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/streak_sync_service.dart';
import 'package:msbridge/core/services/sync/templates_sync.dart';
import 'package:msbridge/core/services/sync/custom_theme_sync.dart';
import 'package:msbridge/core/services/telemetry/telemetry.dart';

class AutoSyncScheduler {
  static const String _prefKeyMinutes = 'cloud_sync_interval_minutes';
  static const String _templatesPrefKeyMinutes =
      'templates_sync_interval_minutes';
  static Timer? _timer;
  static Timer? _templatesTimer;
  static Timer? _streakTimer;
  static bool _isSyncing = false;
  static bool _isTemplatesSyncing = false;
  static bool _isStreakSyncing = false;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_prefKeyMinutes) ?? 0; // 0 = off
    _rescheduleInternal(minutes);
    final tMinutes = prefs.getInt(_templatesPrefKeyMinutes) ?? 0; // 0 = off
    _rescheduleTemplatesInternal(tMinutes);
    _rescheduleStreakInternal(30);
    // Initialize custom theme sync
    await CustomThemeSyncService.initialize();
  }

  static Future<void> setIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyMinutes, minutes);
    _rescheduleInternal(minutes);
  }

  static Future<int> getIntervalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKeyMinutes) ?? 0;
  }

  // Templates-specific interval controls
  static Future<void> setTemplatesIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_templatesPrefKeyMinutes, minutes);
    _rescheduleTemplatesInternal(minutes);
  }

  static Future<int> getTemplatesIntervalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_templatesPrefKeyMinutes) ?? 0;
  }

  static void _rescheduleInternal(int minutes) {
    _timer?.cancel();
    if (minutes <= 0) return; // off
    _timer = Timer.periodic(Duration(minutes: minutes), (_) async {
      // Respect cloud sync toggle
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('cloud_sync_enabled') ?? true;
      if (!enabled) return;
      if (await Telemetry.isKillSwitchOn()) return;
      // Serialize runs to avoid overlap
      if (_isSyncing) return;
      _isSyncing = true;
      final span = Telemetry.start('notes.periodicSync');
      try {
        await SyncService().syncLocalNotesToFirebase();
      } catch (e, st) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'Failed to sync notes',
        );
      } finally {
        span.end();
        _isSyncing = false;
      }
    });
  }

  static void _rescheduleTemplatesInternal(int minutes) {
    _templatesTimer?.cancel();
    if (minutes <= 0) return; // off
    _templatesTimer = Timer.periodic(Duration(minutes: minutes), (_) async {
      // Respect global + templates toggles
      final prefs = await SharedPreferences.getInstance();
      final global = prefs.getBool('cloud_sync_enabled') ?? true;
      final tpl = prefs.getBool('templates_cloud_sync_enabled') ?? true;
      final tplEnabled = prefs.getBool('templates_enabled') ?? true;
      if (!(global && tpl && tplEnabled)) return;
      if (await Telemetry.isKillSwitchOn()) return;
      if (_isTemplatesSyncing) return;
      _isTemplatesSyncing = true;
      final span = Telemetry.start('templates.periodicSync');
      try {
        await TemplatesSyncService().syncLocalTemplatesToFirebase();
      } catch (e, st) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'Failed to sync templates',
        );
      } finally {
        span.end();
        _isTemplatesSyncing = false;
      }
    });
  }

  static void _rescheduleStreakInternal(int minutes) {
    _streakTimer?.cancel();
    if (minutes <= 0) return;
    _streakTimer = Timer.periodic(Duration(minutes: minutes), (_) async {
      final prefs = await SharedPreferences.getInstance();
      final global = prefs.getBool('cloud_sync_enabled') ?? true;
      final streakEnabled = prefs.getBool('streak_cloud_sync_enabled') ?? true;
      if (!(global && streakEnabled)) return;
      if (await Telemetry.isKillSwitchOn()) return;
      if (_isStreakSyncing) return;
      _isStreakSyncing = true;
      final span = Telemetry.start('streak.periodicSync');
      try {
        await StreakSyncService().pullCloudToLocal();
        await StreakSyncService().pushTodayIfDue();
      } catch (e, st) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'Failed to sync streak',
        );
      } finally {
        span.end();
        _isStreakSyncing = false;
      }
    });
  }
}
