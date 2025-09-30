// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/widgets.dart';

// Package imports:
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// Project imports:
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/database/note_taking/note_version.dart';
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/repo/streak_repo.dart';
import 'package:msbridge/core/repo/streak_settings_repo.dart';
import 'package:msbridge/core/services/delete/deletion_sync_integration_service.dart';
import 'package:msbridge/core/services/device_ID/device_id_service.dart';
import 'package:msbridge/core/services/notifications/streak_notification_service.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/reverse_sync.dart';
import 'package:msbridge/core/services/sync/settings_sync_service.dart';
import 'package:msbridge/core/services/sync/streak_sync_service.dart';
import 'package:msbridge/core/services/sync/templates_sync.dart';
import 'package:msbridge/core/services/sync/version_sync_service.dart';

class BgTasks {
  static const String taskPeriodicAll = 'msbridge.periodic.all';
}

// Helper method to get sync status for debugging
Future<Map<String, dynamic>> getSyncStatus() async {
  final prefs = await SharedPreferences.getInstance();
  final lastSyncTimestamp =
      prefs.getInt('bg_sync_last_completed_timestamp') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  final hoursSinceLastSync = (now - lastSyncTimestamp) / (1000 * 60 * 60);

  return {
    'lastSyncTimestamp': lastSyncTimestamp,
    'currentTimestamp': now,
    'hoursSinceLastSync': hoursSinceLastSync,
    'isOverdue': hoursSinceLastSync > 6,
    'lastSyncStatus': prefs.getString('bg_sync_last_status'),
    'lastSyncMessage': prefs.getString('bg_sync_last_message'),
    'lastSyncCompleted': prefs.getString('bg_sync_last_completed'),
    'reverseSyncLastCompleted': prefs.getString('reverse_sync_last_completed'),
    'notesSyncLastCompleted': prefs.getString('notes_sync_last_completed'),
    'settingsSyncLastCompleted':
        prefs.getString('settings_sync_last_completed'),
  };
}

@pragma('vm:entry-point')
Future<void> callbackDispatcher() async {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      // Ensure Firebase is available for Crashlytics in background isolate
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      try {
        final Directory dir = await getApplicationDocumentsDirectory();
        Hive.init(dir.path);
        if (!Hive.isAdapterRegistered(MSNoteAdapter().typeId)) {
          Hive.registerAdapter(MSNoteAdapter());
        }
        if (!Hive.isAdapterRegistered(NoteTakingModelAdapter().typeId)) {
          Hive.registerAdapter(NoteTakingModelAdapter());
        }
        if (!Hive.isAdapterRegistered(NoteVersionAdapter().typeId)) {
          Hive.registerAdapter(NoteVersionAdapter());
        }
        if (!Hive.isAdapterRegistered(ChatHistoryAdapter().typeId)) {
          Hive.registerAdapter(ChatHistoryAdapter());
        }
        if (!Hive.isAdapterRegistered(ChatHistoryMessageAdapter().typeId)) {
          Hive.registerAdapter(ChatHistoryMessageAdapter());
        }
        if (!Hive.isAdapterRegistered(NoteTemplateAdapter().typeId)) {
          Hive.registerAdapter(NoteTemplateAdapter());
        }
        // Open commonly used boxes if needed by repos
        try {
          await Hive.openBox<MSNote>('notesBox');
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to open notesBox'),
            StackTrace.current,
            reason: 'Failed to open notesBox: $e',
          );
        }
        try {
          await Hive.openBox<NoteTakingModel>('notes');
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to open notes'),
            StackTrace.current,
            reason: 'Failed to open notes: $e',
          );
        }
        try {
          await Hive.openBox<NoteTakingModel>('deleted_notes');
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to open deleted_notes'),
            StackTrace.current,
            reason: 'Failed to open deleted_notes: $e',
          );
        }
        try {
          await Hive.openBox<NoteVersion>('note_versions');
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to open note_versions'),
            StackTrace.current,
            reason: 'Failed to open note_versions: $e',
          );
        }
        try {
          await Hive.openBox<ChatHistory>('chat_history');
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to open chat_history'),
            StackTrace.current,
            reason: 'Failed to open chat_history: $e',
          );
        }
        try {
          await Hive.openBox<NoteTemplate>('note_templates');
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to open note_templates'),
            StackTrace.current,
            reason: 'Failed to open note_templates: $e',
          );
        }
      } catch (e, st) {
        await FirebaseCrashlytics.instance.recordError(
          e,
          st,
          reason: 'Hive init/open failed in background',
        );
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Failed to initialize background task: $e',
      );
    }

    try {
      switch (task) {
        case BgTasks.taskPeriodicAll:
          // Run a compact background sync bundle
          await AutoSyncScheduler.initialize();

          final prefs = await SharedPreferences.getInstance();
          final kill = prefs.getBool('sync_kill_switch') ?? false;
          if (kill) {
            await prefs.setString('bg_sync_last_status', 'skipped');
            await prefs.setString(
                'bg_sync_last_message', 'Skipped: kill switch enabled');
            await prefs.setInt(
                'bg_sync_last_ended_at', DateTime.now().millisecondsSinceEpoch);
            FirebaseCrashlytics.instance
                .log('Background sync skipped by kill switch');
            return Future.value(true);
          }

          // Check if sync is overdue (more than 6 hours since last sync)
          final lastSyncTimestamp =
              prefs.getInt('bg_sync_last_completed_timestamp') ?? 0;
          final now = DateTime.now().millisecondsSinceEpoch;
          final hoursSinceLastSync =
              (now - lastSyncTimestamp) / (1000 * 60 * 60);
          final isOverdue = hoursSinceLastSync > 6;

          // Capture the overdue values before any timestamp updates
          final capturedHoursSinceLastSync = hoursSinceLastSync;
          final capturedIsOverdue = isOverdue;

          if (capturedIsOverdue) {
            FirebaseCrashlytics.instance.log(
                'Background sync overdue by ${capturedHoursSinceLastSync.toStringAsFixed(1)} hours, forcing sync');
            await prefs.setString(
                'bg_sync_last_message', 'Forced sync due to being overdue');
          }

          final global = prefs.getBool('cloud_sync_enabled') ?? true;
          if (global) {
            bool overallSuccess = true;
            String message = 'Background sync completed successfully';
            // Wait briefly for Firebase Auth session to hydrate in bg isolate
            User? user = FirebaseAuth.instance.currentUser;
            if (user == null) {
              try {
                user = await FirebaseAuth.instance
                    .idTokenChanges()
                    .firstWhere((u) => u != null)
                    .timeout(const Duration(seconds: 3), onTimeout: () => null);
              } catch (e) {
                FirebaseCrashlytics.instance.recordError(
                  e,
                  StackTrace.current,
                  reason: 'Failed to get user in background',
                );
                user = null;
              }
            }

            if (user == null) {
              FirebaseCrashlytics.instance.log(
                  'Background sync skipped: no authenticated user in worker');
              await prefs.setString('bg_sync_last_status', 'skipped');
              await prefs.setString(
                  'bg_sync_last_message', 'Skipped: not signed in');
              await prefs.setInt('bg_sync_last_ended_at',
                  DateTime.now().millisecondsSinceEpoch);
              return Future.value(true); // skip quietly; no permission errors
            }
            try {
              await user.getIdToken(true); // ensure fresh token
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Failed to get user token in background',
              );
            }

            // Pull cloud → local first (notes, versions, settings)
            try {
              FirebaseCrashlytics.instance
                  .log('Starting reverse sync (cloud → local)');
              await ReverseSyncService().syncDataFromFirebaseToHive();
              FirebaseCrashlytics.instance
                  .log('Reverse sync completed successfully');

              // Update last sync timestamp
              await prefs.setString('reverse_sync_last_completed',
                  DateTime.now().toIso8601String());
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Reverse sync failed',
              );
              overallSuccess = false;
              message = 'Reverse sync failed';
            }

            // Notes push (local → cloud)
            try {
              FirebaseCrashlytics.instance
                  .log('Starting notes sync (local → cloud)');
              await SyncService().syncLocalNotesToFirebase();
              FirebaseCrashlytics.instance
                  .log('Notes sync completed successfully');

              // Update last sync timestamp
              await prefs.setString('notes_sync_last_completed',
                  DateTime.now().toIso8601String());
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Notes sync failed',
              );
              overallSuccess = false;
              message = 'Notes sync failed';
            }

            // Templates
            try {
              FirebaseCrashlytics.instance
                  .log('Starting templates sync (local → cloud)');
              await TemplatesSyncService().syncLocalTemplatesToFirebase();
              FirebaseCrashlytics.instance
                  .log('Templates sync completed successfully');
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Templates sync failed',
              );
              overallSuccess = false;
              message = 'Templates sync failed';
            }

            // Templates pull (cloud → local)
            try {
              FirebaseCrashlytics.instance
                  .log('Starting templates pull (cloud → local)');
              await TemplatesSyncService().pullTemplatesFromCloud();
              FirebaseCrashlytics.instance
                  .log('Templates pull completed successfully');
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Templates pull failed',
              );
              overallSuccess = false;
              message = 'Templates pull failed';
            }

            // Versions push (local → cloud)
            try {
              FirebaseCrashlytics.instance
                  .log('Starting versions sync (local → cloud)');
              await VersionSyncService().syncLocalVersionsToFirebase();
              FirebaseCrashlytics.instance
                  .log('Versions sync completed successfully');
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Versions sync failed',
              );
              overallSuccess = false;
              message = 'Versions sync failed';
            }

            // Settings bidirectional sync
            try {
              FirebaseCrashlytics.instance
                  .log('Starting settings bidirectional sync');
              await SettingsSyncService().syncSettingsBidirectional();
              FirebaseCrashlytics.instance
                  .log('Settings sync completed successfully');

              // Update last sync timestamp
              await prefs.setString('settings_sync_last_completed',
                  DateTime.now().toIso8601String());
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Settings sync failed',
              );
              overallSuccess = false;
              message = 'Settings sync failed';
            }

            // Streak (pull then push daily)
            try {
              FirebaseCrashlytics.instance
                  .log('Starting streak sync (pull then push)');
              await StreakSyncService().pullCloudToLocal();
              await StreakSyncService().pushTodayIfDue();
              FirebaseCrashlytics.instance
                  .log('Streak sync completed successfully');

              // After streak sync, reschedule local notifications
              try {
                final settings = await StreakSettingsRepo.getStreakSettings();
                final streak = await StreakRepo.getStreakData();
                await StreakNotificationService.evaluateAndScheduleAll(
                  notificationsEnabled: settings.notificationsEnabled &&
                      settings.hasAnyNotificationsEnabled,
                  dailyReminders: settings.dailyReminders,
                  urgentReminders: settings.urgentReminders,
                  dailyTime: settings.notificationTime,
                  soundEnabled: settings.soundEnabled,
                  vibrationEnabled: settings.vibrationEnabled,
                  isStreakAboutToEnd: streak.isStreakAboutToEnd,
                );
                FirebaseCrashlytics.instance.log(
                    'Streak notifications scheduled from background worker');
              } catch (e, st) {
                await FirebaseCrashlytics.instance.recordError(
                  e,
                  st,
                  reason: 'Failed scheduling streak notifications in worker',
                );
              }
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Streak sync failed',
              );
              overallSuccess = false;
              message = 'Streak sync failed';
            }

            // Update overall sync timestamp
            await prefs.setString(
                'bg_sync_last_completed', DateTime.now().toIso8601String());
            await prefs.setInt('bg_sync_last_completed_timestamp',
                DateTime.now().millisecondsSinceEpoch);

            // Check if this was a forced sync due to being overdue
            // Use the captured values from the beginning to avoid timestamp overwrite issues
            if (capturedIsOverdue) {
              FirebaseCrashlytics.instance.log(
                  'Background sync was overdue by ${capturedHoursSinceLastSync.toStringAsFixed(1)} hours');
              await prefs.setString(
                  'bg_sync_last_message', 'Forced sync due to being overdue');
            }

            // Deletion sync operations
            try {
              // Initialize device ID if needed
              await DeviceIdService.getDeviceId();

              // Process deletions during sync
              await DeletionSyncIntegrationService.processDeletionsDuringSync(
                  user.uid);

              // Resolve deletion conflicts
              await DeletionSyncIntegrationService.resolveDeletionConflicts(
                  user.uid);

              // Perform cleanup (only once per day to avoid excessive operations)
              final lastCleanup = prefs.getInt('last_deletion_cleanup') ?? 0;
              final now = DateTime.now().millisecondsSinceEpoch;
              final oneDayInMs = 24 * 60 * 60 * 1000;

              if (now - lastCleanup > oneDayInMs) {
                await DeletionSyncIntegrationService.performCleanup(user.uid);
                await prefs.setInt('last_deletion_cleanup', now);
                FirebaseCrashlytics.instance.log('Deletion cleanup completed');
              }

              FirebaseCrashlytics.instance
                  .log('Deletion sync completed successfully');
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Deletion sync failed in background task',
              );
              overallSuccess = false;
              message = 'Deletion sync failed';
            }

            await prefs.setString(
                'bg_sync_last_status', overallSuccess ? 'success' : 'failed');
            await prefs.setString('bg_sync_last_message', message);
            await prefs.setInt(
                'bg_sync_last_ended_at', DateTime.now().millisecondsSinceEpoch);
          }
          break;
        default:
          break;
      }
      return Future.value(true);
    } catch (e, st) {
      try {
        await FirebaseCrashlytics.instance
            .recordError(e, st, reason: 'Workmanager task failed: $task');
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason: 'Failed to record error: $e',
        );
      }
      return Future.value(false);
    }
  });
}
