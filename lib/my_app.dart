// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

// Project imports:
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/core/repo/auth_gate.dart';
import 'package:msbridge/core/wrapper/main_wrapper.dart';
import 'package:msbridge/main.dart';
import 'package:msbridge/theme/colors.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return PostHogWidget(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorObservers: [PosthogObserver()],
            navigatorKey: navigatorKey,
            theme: _buildTheme(themeProvider, false),
            darkTheme: _buildTheme(themeProvider, true),
            themeMode: themeProvider.selectedTheme == AppTheme.light
                ? ThemeMode.light
                : ThemeMode.dark,
            home: const SecurityWrapper(child: AuthGate()),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: [
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('en'),
            ],
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(ThemeProvider themeProvider, bool isDark) {
    return themeProvider.getThemeData();
  }
}
