import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinLockProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const String _pinKey = 'app_pin_code';
  static const String _enabledKey = 'app_pin_enabled';

  bool _enabled = false;
  bool get enabled => _enabled;

  PinLockProvider() {
    _load();
  }

  Future<void> _load() async {
    final en = await _storage.read(key: _enabledKey);
    _enabled = en == 'true';
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _storage.write(key: _enabledKey, value: value.toString());
    notifyListeners();
  }

  Future<bool> hasPin() async {
    final pin = await _storage.read(key: _pinKey);
    return (pin != null && pin.isNotEmpty);
  }

  Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<String?> readPin() async {
    return await _storage.read(key: _pinKey);
  }
}
