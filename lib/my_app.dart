import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:msbridge/core/dynamic_link/dynamic_link.dart';
import 'package:msbridge/core/provider/theme_provider.dart';
import 'package:msbridge/core/wrapper/authrntication_wrapper.dart';
import 'package:msbridge/main.dart';
import 'package:msbridge/theme/colors.dart';
import 'package:provider/provider.dart';

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
      home: const AuthenticationWrapper(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('en'),
      ],
      navigatorObservers: [
        DynamicLinkObserver(),
      ],
    );
  }

  ThemeData _buildTheme(ThemeProvider themeProvider, bool isDark) {
    return themeProvider.getThemeData();
  }
}
