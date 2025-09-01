import 'package:flutter/material.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'appTheme';
  static const String _dynamicColorsKey = 'dynamicColors';

  AppTheme _selectedTheme = AppTheme.dark;
  bool _dynamicColorsEnabled = false;

  AppTheme get selectedTheme => _selectedTheme;
  bool get dynamicColorsEnabled => _dynamicColorsEnabled;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? themeName = prefs.getString(_themeKey);
      bool? dynamicColors = prefs.getBool(_dynamicColorsKey);

      _selectedTheme = _themeFromString(themeName);
      _dynamicColorsEnabled = dynamicColors ?? false;
    } catch (e) {
      _selectedTheme = AppTheme.dark;
      _dynamicColorsEnabled = false;
      FlutterBugfender.sendCrash(
          'Error loading theme: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Error loading theme: $e',
      );
    }
    notifyListeners();
  }

  AppTheme _themeFromString(String? themeName) {
    if (themeName == null) {
      return AppTheme.dark;
    }

    for (AppTheme theme in AppTheme.values) {
      if (theme.name == themeName) {
        return theme;
      }
    }

    return AppTheme.dark;
  }

  Future<void> setTheme(AppTheme theme) async {
    if (_dynamicColorsEnabled) {
      FlutterBugfender.log(
          'Cannot set custom theme when dynamic colors are enabled');
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
      _selectedTheme = theme;
      notifyListeners();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to set theme: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to set theme: $e',
      );
    }
  }

  Future<void> setDynamicColors(bool enabled) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dynamicColorsKey, enabled);
      _dynamicColorsEnabled = enabled;

      // If enabling dynamic colors, reset to default theme
      if (enabled) {
        _selectedTheme = AppTheme.dark;
        await prefs.setString(_themeKey, AppTheme.dark.name);
      }

      notifyListeners();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to set dynamic colors: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to set dynamic colors: $e',
      );
    }
  }

  ThemeData getThemeData() {
    if (_dynamicColorsEnabled) {
      // Use a custom dynamic color theme that simulates Material You
      return ThemeData(
        useMaterial3: true,
        colorScheme: _generateDynamicColorScheme(),
        // Apply some custom styling while keeping dynamic colors
        textTheme: AppThemes.themeMap[_selectedTheme]!.textTheme,
      );
    }

    return AppThemes.themeMap[_selectedTheme]!;
  }

  // Generate a dynamic color scheme that simulates Material You
  ColorScheme _generateDynamicColorScheme() {
    final isDark = _selectedTheme == AppTheme.dark;

    if (isDark) {
      // Dark dynamic theme with vibrant accents
      return const ColorScheme.dark(
        primary: Color(0xFF81C784), // Green accent
        onPrimary: Colors.black,
        secondary: Color(0xFFFFB74D), // Orange accent
        onSecondary: Colors.black,
        surface: Color(0xFF121212), // Dark surface
        onSurface: Colors.white,
        error: Color(0xFFE57373), // Red accent
        onError: Colors.black,
        outline: Color(0xFF424242),
        shadow: Colors.black,
      );
    } else {
      // Light dynamic theme with warm colors
      return const ColorScheme.light(
        primary: Color(0xFF4CAF50), // Green primary
        onPrimary: Colors.white,
        secondary: Color(0xFFFF9800), // Orange secondary
        onSecondary: Colors.white,
        surface: Color(0xFFFAFAFA), // Light surface
        onSurface: Colors.black87,
        error: Color(0xFFF44336), // Red error
        onError: Colors.white,
        outline: Color(0xFFE0E0E0),
        shadow: Colors.black12,
      );
    }
  }

  String get currentImagePath {
    if (_dynamicColorsEnabled) {
      return 'assets/svg/dynamic_colors.svg';
    }
    return _selectedTheme.imagePath();
  }

  Future<void> resetTheme() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      await prefs.remove(_dynamicColorsKey);
      _selectedTheme = AppTheme.dark;
      _dynamicColorsEnabled = false;
      notifyListeners();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to reset theme: $e', StackTrace.current.toString());
      FlutterBugfender.error(
        'Failed to reset theme: $e',
      );
    }
  }

  // Check if a theme can be selected (disabled when dynamic colors are on)
  bool canSelectTheme(AppTheme theme) {
    return !_dynamicColorsEnabled;
  }

  // Get the current effective theme name for display
  String get effectiveThemeName {
    if (_dynamicColorsEnabled) {
      return 'Dynamic Colors';
    }
    return _selectedTheme.name;
  }
}
