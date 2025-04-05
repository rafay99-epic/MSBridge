import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoSaveProvider with ChangeNotifier {
  bool _autoSaveEnabled = true;

  AutoSaveProvider() {
    _loadAutoSaveSetting();
  }

  bool get autoSaveEnabled => _autoSaveEnabled;

  set autoSaveEnabled(bool value) {
    _autoSaveEnabled = value;
    _saveAutoSaveSetting(value);
    notifyListeners();
  }

  Future<void> _loadAutoSaveSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSaveEnabled = prefs.getBool('autoSaveEnabled') ?? true;
    notifyListeners();
  }

  Future<void> _saveAutoSaveSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoSaveEnabled', value);
  }
}
