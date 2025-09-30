// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:shared_preferences/shared_preferences.dart';

class TemplateSettingsProvider extends ChangeNotifier {
  static const String _enabledKey = 'templates_enabled';
  static const String _syncEnabledKey = 'templates_cloud_sync_enabled';

  bool _enabled = true;
  bool _cloudSyncEnabled = true;

  bool get enabled => _enabled;
  bool get cloudSyncEnabled => _cloudSyncEnabled;

  TemplateSettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    _cloudSyncEnabled = prefs.getBool(_syncEnabledKey) ?? true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    notifyListeners();
  }

  Future<void> setCloudSyncEnabled(bool value) async {
    _cloudSyncEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, value);
    notifyListeners();
  }
}
