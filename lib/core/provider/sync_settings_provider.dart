// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

class SyncSettingsProvider extends ChangeNotifier {
  static const String _prefKey = 'cloud_sync_enabled';
  bool _enabled = true;
  bool get cloudSyncEnabled => _enabled;

  SyncSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? true;
    notifyListeners();
  }

  Future<void> setCloudSyncEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    notifyListeners();
  }
}
