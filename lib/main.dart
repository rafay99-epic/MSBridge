import 'dart:convert';
import 'dart:isolate';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:msbridge/config/feature_flag.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/provider/auto_save_note_provider.dart';
import 'package:msbridge/core/provider/chat_history_provider.dart';
import 'package:msbridge/core/provider/connectivity_provider.dart';
import 'package:msbridge/core/provider/fingerprint_provider.dart';
import 'package:msbridge/core/provider/note_summary_ai_provider.dart';
import 'package:msbridge/core/provider/share_link_provider.dart';
import 'package:msbridge/core/provider/sync_settings_provider.dart';
import 'package:msbridge/core/provider/ai_consent_provider.dart';
import 'package:msbridge/core/provider/app_pin_lock_provider.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/core/provider/todo_provider.dart';
import 'package:msbridge/core/repo/auth_gate.dart';
import 'package:msbridge/core/auth/app_pin_lock_wrapper.dart';
import 'package:msbridge/features/lock/fingerprint_lock_screen.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msbridge/core/services/sync/auto_sync_scheduler.dart';
import 'package:msbridge/utils/error.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/config/config.dart';
import 'package:msbridge/theme/colors.dart';

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

    // Register chat history adapters
    Hive.registerAdapter(ChatHistoryAdapter());
    Hive.registerAdapter(ChatHistoryMessageAdapter());
    await Hive.openBox<ChatHistory>('chat_history');

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
          if (FeatureFlag.enableFingerprintLock)
            ChangeNotifierProvider(create: (_) => FingerprintAuthProvider()),
          if (FeatureFlag.enableAutoSave)
            ChangeNotifierProvider(create: (_) => AutoSaveProvider()),
          ChangeNotifierProvider(create: (_) => ShareLinkProvider()),
          ChangeNotifierProvider(create: (_) => SyncSettingsProvider()),
          ChangeNotifierProvider(create: (_) => AiConsentProvider()),
          ChangeNotifierProvider(create: (_) => AppPinLockProvider()),
          ChangeNotifierProvider(create: (_) => ChatHistoryProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Initialize auto sync scheduler after app providers are ready
    await AutoSyncScheduler.initialize();

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
      theme: _buildTheme(themeProvider, false),
      darkTheme: _buildTheme(themeProvider, true),
      themeMode: themeProvider.selectedTheme == AppTheme.light
          ? ThemeMode.light
          : ThemeMode.dark,
      home: FeatureFlag.enableFingerprintLock
          ? const AppPinLockWrapper(child: FingerprintAuthWrapper())
          : const AppPinLockWrapper(child: AuthGate()),
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        _DynamicLinkObserver(),
      ],
    );
  }

  ThemeData _buildTheme(ThemeProvider themeProvider, bool isDark) {
    // Use the theme provider's getThemeData method which handles dynamic colors
    return themeProvider.getThemeData();
  }
}

class _DynamicLinkObserver extends NavigatorObserver {
  _DynamicLinkObserver() {
    _initDynamicLinks();
  }

  void _initDynamicLinks() async {
    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink?.link != null) {
      _handleLink(initialLink!.link);
    }

    FirebaseDynamicLinks.instance.onLink.listen((data) {
      _handleLink(data.link);
    });
  }

  void _handleLink(Uri link) async {
    try {
      final Uri deep = link;
      final Uri target = deep;
      final List<String> parts =
          target.path.split('/').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2 && parts[0] == 's') {
        final String shareId = parts[1];
        // Fetch and show a simple in-app viewer dialog
        final doc = await FirebaseFirestore.instance
            .collection('shared_notes')
            .doc(shareId)
            .get();
        final state = navigatorKey.currentState;
        if (state == null || !state.mounted) return;
        if (!doc.exists) {
          _showSnack('This shared note does not exist or was disabled.');
          return;
        }
        final data = doc.data() as Map<String, dynamic>;
        if (data['viewOnly'] != true) {
          _showSnack('This link is not viewable.');
          return;
        }
        _showSharedViewer(
          title: (data['title'] as String?) ?? 'Untitled',
          content: (data['content'] as String?) ?? '',
        );
      }
    } catch (e, st) {
      await FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'DynamicLink handling failed');
    }
  }

  void _showSnack(String message) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSharedViewer({required String title, required String content}) {
    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        String plain;
        try {
          final parsed = _tryParseQuill(content);
          plain = parsed;
        } catch (_) {
          plain = content;
        }
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title:
              Text(title, style: TextStyle(color: theme.colorScheme.primary)),
          content: SingleChildScrollView(
            child:
                Text(plain, style: TextStyle(color: theme.colorScheme.primary)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }
}

String _tryParseQuill(String content) {
  try {
    final dynamic json = _jsonDecode(content);
    if (json is List) {
      return json
          .map((op) =>
              op is Map && op['insert'] is String ? op['insert'] as String : '')
          .join('');
    }
    if (json is Map && json['ops'] is List) {
      final List ops = json['ops'];
      return ops
          .map((op) =>
              op is Map && op['insert'] is String ? op['insert'] as String : '')
          .join('');
    }
  } catch (_) {}
  return content;
}

dynamic _jsonDecode(String s) {
  return jsonDecode(s);
}
