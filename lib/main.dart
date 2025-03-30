import 'dart:isolate';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:msbridge/core/api/ms_notes_api.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/core/provider/connectivity_provider.dart';
import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/core/provider/todo_provider.dart';
import 'package:msbridge/core/repo/auth_gate.dart';
import 'package:msbridge/core/services/sync/note_taking_sync.dart';
import 'package:msbridge/utils/error.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/config/config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await Hive.initFlutter();
    Hive.registerAdapter(MSNoteAdapter());
    await Hive.openBox<MSNote>('notesBox');
    Hive.registerAdapter(NoteTakingModelAdapter());
    await Hive.openBox<NoteTakingModel>('notes_taking');
    await Hive.openBox<NoteTakingModel>('deleted_notes');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(
              create: (context) =>
                  ConnectivityProvider(navigatorKey: navigatorKey)),
          ChangeNotifierProvider(
              create: (context) => TodoProvider()..initialize()),
          ChangeNotifierProvider(
            create: (_) => NoteSummaryProvider(apiKey: NoteSummaryAPI.apiKey),
          ),
          ChangeNotifierProvider(
            create: (_) => AutoSaveProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final syncService = SyncService();
      await syncService.startListening();
      ApiService.fetchAndSaveNotes();
    });

    // recording any error and send to firebase
    bool weWantFatalErrorRecording = true;
    FlutterError.onError = (errorDetails) {
      if (weWantFatalErrorRecording) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // error handelling outside the flutter scopr
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair;
      await FirebaseCrashlytics.instance.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last,
        fatal: true,
      );
    }).sendPort);
  } catch (e) {
    runApp(ErrorApp(errorMessage: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: themeProvider.getThemeData(),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
