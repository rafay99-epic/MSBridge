import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShareLinkProvider extends ChangeNotifier {
  static const String _prefKey = 'share_links_enabled';

  bool _shareLinksEnabled = true;
  bool get shareLinksEnabled => _shareLinksEnabled;

  ShareLinkProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _shareLinksEnabled = prefs.getBool(_prefKey) ?? true;
      notifyListeners();
    } catch (_) {}
  }

  set shareLinksEnabled(bool value) {
    if (_shareLinksEnabled == value) return;
    _shareLinksEnabled = value;
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, _shareLinksEnabled);
    } catch (_) {}
  }
}
