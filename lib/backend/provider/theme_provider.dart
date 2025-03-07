import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDarkMode = prefs.getBool(_themeKey);

    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }

    notifyListeners();
  }

  Future<void> toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
      await prefs.setBool(_themeKey, false);
    } else {
      _themeMode = ThemeMode.dark;
      await prefs.setBool(_themeKey, true);
    }

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeMode = mode;
    if (_themeMode == ThemeMode.dark) {
      await prefs.setBool(_themeKey, true);
    } else if (_themeMode == ThemeMode.light) {
      await prefs.setBool(_themeKey, false);
    } else {
      await prefs.remove(_themeKey);
    }
    notifyListeners();
  }
}
