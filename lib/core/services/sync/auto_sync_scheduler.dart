import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/templates_sync.dart';

class AutoSyncScheduler {
  static const String _prefKeyMinutes = 'cloud_sync_interval_minutes';
  static const String _templatesPrefKeyMinutes =
      'templates_sync_interval_minutes';
  static Timer? _timer;
  static Timer? _templatesTimer;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_prefKeyMinutes) ?? 0; // 0 = off
    _rescheduleInternal(minutes);
    final tMinutes = prefs.getInt(_templatesPrefKeyMinutes) ?? 0; // 0 = off
    _rescheduleTemplatesInternal(tMinutes);
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
      // Fire and forget
      SyncService().syncLocalNotesToFirebase();
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
      TemplatesSyncService().syncLocalTemplatesToFirebase();
    });
  }
}
