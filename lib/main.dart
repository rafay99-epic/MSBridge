import 'dart:isolate';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/ai/chat_provider.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/database/note_taking/note_version.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/core/provider/chat_history_provider.dart';
import 'package:msbridge/core/provider/lock_provider/fingerprint_provider.dart';
import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/core/provider/sync_settings_provider.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';
import 'package:msbridge/core/provider/lock_provider/app_pin_lock_provider.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/core/provider/todo_provider.dart';
import 'package:msbridge/core/provider/streak_provider.dart';
import 'package:msbridge/core/provider/note_version_provider.dart';
import 'package:msbridge/core/provider/user_settings_provider.dart';
import 'package:msbridge/core/provider/font_provider.dart';
import 'package:msbridge/core/provider/template_settings_provider.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:msbridge/my_app.dart';
import 'package:msbridge/utils/error.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/config/config.dart';
import 'package:workmanager/workmanager.dart';
import 'package:msbridge/core/services/background/workmanager_dispatcher.dart';
import 'package:msbridge/core/services/background/scheduler_registration.dart';
import 'package:msbridge/core/provider/uploadthing_provider.dart';
import 'package:msbridge/core/provider/voice_note_settings_provider.dart';
import 'package:msbridge/core/provider/haptic_feedback_settings_provider.dart';
import 'package:msbridge/core/services/update_app/update_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterBugfender.init(BugfenderConfig.apiKey,
      enableCrashReporting: false,
      enableUIEventLogging: true,
      enableAndroidLogcatLogging: true);

  try {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  } catch (e, s) {
    FlutterBugfender.sendCrash('Failed to set preferred orientations: $e',
        StackTrace.current.toString());
    FlutterBugfender.error('Failed to set preferred orientations: $e');
    FlutterBugfender.log('stack: $s');
  }

  try {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Firebase init failed: $e', StackTrace.current.toString());
    }
    try {
      await Hive.initFlutter();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Hive init failed: $e', StackTrace.current.toString());
    }

    Hive.registerAdapter(MSNoteAdapter());
    await Hive.openBox<MSNote>('notesBox');
    Hive.registerAdapter(NoteTakingModelAdapter());
    await Hive.openBox<NoteTakingModel>('notes');
    await Hive.openBox<NoteTakingModel>('deleted_notes');

    // Register note version adapter
    Hive.registerAdapter(NoteVersionAdapter());
    await Hive.openBox<NoteVersion>('note_versions');

    // Register chat history adapters
    Hive.registerAdapter(ChatHistoryAdapter());
    Hive.registerAdapter(ChatHistoryMessageAdapter());
    await Hive.openBox<ChatHistory>('chat_history');

    // Register templates adapter
    Hive.registerAdapter(NoteTemplateAdapter());
    await Hive.openBox<NoteTemplate>('note_templates');

    // Register voice notes adapter
    Hive.registerAdapter(VoiceNoteModelAdapter());
    await Hive.openBox<VoiceNoteModel>('voice_notes');

    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      await SchedulerRegistration.registerAdaptive();
    } catch (e, st) {
      FlutterBugfender.log('Workmanager init failed: $e');
      FlutterBugfender.error(e.toString());
      FlutterBugfender.sendCrash('Workmanager init failed: $e', st.toString());
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(
              create: (context) => TodoProvider()..initialize()),
          ChangeNotifierProvider(
            create: (_) => NoteSummaryProvider(apiKey: NoteSummaryAPI.apiKey),
          ),
          ChangeNotifierProvider(create: (_) => NoteVersionProvider()),
          ChangeNotifierProvider(create: (_) => UserSettingsProvider()),
          ChangeNotifierProvider(create: (_) => FontProvider()),
          ChangeNotifierProvider(create: (_) => FingerprintAuthProvider()),
          if (FeatureFlag.enableAutoSave)
            ChangeNotifierProvider(create: (_) => AutoSaveProvider()),
          ChangeNotifierProvider(create: (_) => ShareLinkProvider()),
          ChangeNotifierProvider(create: (_) => SyncSettingsProvider()),
          ChangeNotifierProvider(create: (_) => TemplateSettingsProvider()),
          ChangeNotifierProvider(create: (_) => AiConsentProvider()),
          ChangeNotifierProvider(create: (_) => AppPinLockProvider()),
          ChangeNotifierProvider(create: (_) => ChatHistoryProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
          ChangeNotifierProvider(create: (_) => UploadThingProvider()),
          ChangeNotifierProvider(create: (_) => VoiceNoteSettingsProvider()),
          ChangeNotifierProvider(
              create: (_) => HapticFeedbackSettingsProvider()),
          ChangeNotifierProvider(create: (_) => StreakProvider()),
        ],
        child: const MyApp(),
      ),
    );
    try {
      await AutoSyncScheduler.initialize();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'AutoSyncScheduler Error: $e', StackTrace.current.toString());
    }

    try {
      await UpdateManager.initialize();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'UpdateManager Error: $e', StackTrace.current.toString());
    }

    FlutterError.onError = (errorDetails) {
      FlutterBugfender.sendCrash('Flutter Error: ${errorDetails.exception}',
          errorDetails.stack.toString());
      FlutterBugfender.error('Flutter Error: ${errorDetails.exception}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FlutterBugfender.sendCrash('Platform Error: $error', stack.toString());
      FlutterBugfender.error('Platform Error: $error');
      return true;
    };

    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      FlutterBugfender.sendCrash('Isolate Error: ${errorAndStacktrace.first}',
          errorAndStacktrace.last.toString());
      FlutterBugfender.error('Isolate Error: ${errorAndStacktrace.first}');
    }).sendPort);
  } catch (e) {
    FlutterBugfender.sendCrash(e.toString(), StackTrace.current.toString());
    runApp(ErrorApp(errorMessage: e.toString()));
  }
}
