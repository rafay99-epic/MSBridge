import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/database/note_taking/note_version.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:flutter/widgets.dart';
import 'package:msbridge/core/services/sync/streak_sync_service.dart';
import 'package:msbridge/core/services/sync/templates_sync.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/core/services/sync/version_sync_service.dart';
import 'package:msbridge/core/services/sync/settings_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:msbridge/core/services/sync/reverse_sync.dart';

class BgTasks {
  static const String taskPeriodicAll = 'msbridge.periodic.all';
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
        try {
          Hive.registerAdapter(MSNoteAdapter());
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to register MSNoteAdapter'),
            StackTrace.current,
            reason: 'Failed to register MSNoteAdapter: $e',
          );
        }
        try {
          Hive.registerAdapter(NoteTakingModelAdapter());
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to register NoteTakingModelAdapter'),
            StackTrace.current,
            reason: 'Failed to register NoteTakingModelAdapter: $e',
          );
        }
        try {
          Hive.registerAdapter(NoteVersionAdapter());
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to register NoteVersionAdapter'),
            StackTrace.current,
            reason: 'Failed to register NoteVersionAdapter: $e',
          );
        }
        try {
          Hive.registerAdapter(ChatHistoryAdapter());
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to register ChatHistoryAdapter'),
            StackTrace.current,
            reason: 'Failed to register ChatHistoryAdapter: $e',
          );
        }
        try {
          Hive.registerAdapter(ChatHistoryMessageAdapter());
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to register ChatHistoryMessageAdapter'),
            StackTrace.current,
            reason: 'Failed to register ChatHistoryMessageAdapter: $e',
          );
        }
        try {
          Hive.registerAdapter(NoteTemplateAdapter());
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            Exception('Failed to register NoteTemplateAdapter'),
            StackTrace.current,
            reason: 'Failed to register NoteTemplateAdapter: $e',
          );
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
              await ReverseSyncService().syncDataFromFirebaseToHive();
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Reverse sync failed',
              );
              overallSuccess = false;
              message = 'Reverse sync failed';
            }
            // Notes push
            try {
              await SyncService().syncLocalNotesToFirebase();
            } catch (e) {
              overallSuccess = false;
              message = 'Notes sync failed';
            }
            // Templates
            try {
              await TemplatesSyncService().syncLocalTemplatesToFirebase();
            } catch (e) {
              overallSuccess = false;
              message = 'Templates sync failed';
            }
            // Templates pull
            try {
              await TemplatesSyncService().pullTemplatesFromCloud();
            } catch (e) {
              FirebaseCrashlytics.instance.recordError(
                e,
                StackTrace.current,
                reason: 'Templates pull failed',
              );
              overallSuccess = false;
              message = 'Templates pull failed';
            }
            // Versions push
            try {
              await VersionSyncService().syncLocalVersionsToFirebase();
            } catch (e) {
              overallSuccess = false;
              message = 'Versions sync failed';
            }
            // Settings bidirectional
            try {
              await SettingsSyncService().syncSettingsBidirectional();
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
              await StreakSyncService().pullCloudToLocal();
              await StreakSyncService().pushTodayIfDue();
            } catch (e) {
              overallSuccess = false;
              message = 'Streak sync failed';
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
