import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiConsentProvider extends ChangeNotifier {
  static const String _prefKey = 'ai_notes_access_enabled';
  bool _enabled = false;

  bool get enabled => _enabled;

  AiConsentProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    notifyListeners();
  }
}
