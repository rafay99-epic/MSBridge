// Dart imports:
import 'dart:async';

// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/core/repo/custom_color_scheme_repo.dart';
import 'package:msbridge/core/services/telemetry/telemetry.dart';

class CustomThemeSyncService {
  static const String _prefKeyMinutes = 'custom_themes_sync_interval_minutes';
  static Timer? _timer;
  static bool _isSyncing = false;

  /// Initialize the custom theme sync service
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_prefKeyMinutes) ?? 15; // Default 15 minutes
    _rescheduleInternal(minutes);
  }

  /// Set sync interval in minutes
  static Future<void> setIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyMinutes, minutes);
    _rescheduleInternal(minutes);
  }

  /// Get current sync interval
  static Future<int> getIntervalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKeyMinutes) ?? 15;
  }

  /// Reschedule the sync timer
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

      final span = Telemetry.start('customThemes.periodicSync');
      try {
        await _performBackgroundSync();
      } catch (e, st) {
        FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'Failed to sync custom themes',
        );
      } finally {
        span.end();
        _isSyncing = false;
      }
    });
  }

  /// Perform background sync of custom themes
  static Future<void> _performBackgroundSync() async {
    final repo = CustomColorSchemeRepo.instance;

    // 1. Sync local themes to Firebase
    await repo.syncAllToFirebase();

    // 2. Handle pending deletions
    await _handlePendingDeletions();

    // 3. Pull any new themes from Firebase
    await repo.syncFromFirebase();
  }

  /// Handle pending deletions from Firebase
  static Future<void> _handlePendingDeletions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = prefs.getStringList('deleted_custom_themes') ?? [];

      if (deletedIds.isNotEmpty) {
        final List<String> remainingIds = [];

        for (final schemeId in deletedIds) {
          try {
            // Delete from Firebase
            await _deleteFromFirebase(schemeId);
            // Successfully deleted, don't add to remaining list
          } catch (e) {
            // Failed to delete, keep it in the list for next attempt
            remainingIds.add(schemeId);
            FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                reason:
                    'Failed to delete custom theme from Firebase: $schemeId');
          }
        }

        // Update the pending deletions list with only the remaining ones
        await prefs.setStringList('deleted_custom_themes', remainingIds);
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: 'Failed to handle pending deletions');
    }
  }

  /// Delete a scheme from Firebase
  static Future<void> _deleteFromFirebase(String schemeId) async {
    try {
      final repo = CustomColorSchemeRepo.instance;
      // Use the existing Firebase deletion logic from the repo
      await repo.deleteFromFirebaseDirect(schemeId);
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to delete custom theme from Firebase: $schemeId',
          StackTrace.current.toString());
    }
  }

  /// Manual sync trigger
  static Future<bool> syncNow() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    try {
      await _performBackgroundSync();
      return true;
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to perform manual custom theme sync: $e',
          StackTrace.current.toString());
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Stop the sync service
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
