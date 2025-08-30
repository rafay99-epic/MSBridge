import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinRepository {
  static const _storage = FlutterSecureStorage();
  static const String _pinKey = 'app_pin_lock_code';
  static const String _enabledKey = 'app_pin_lock_enabled';

  // Read operations
  Future<bool> isPinEnabled() async {
    try {
      final enabled = await _storage.read(key: _enabledKey);
      final result = enabled == 'true';
      FlutterBugfender.log("REPO: Read isPinEnabled=$result");
      return result;
    } catch (e) {
      FlutterBugfender.error(
          "REPO ERROR: isPinEnabled failed - ${e.toString()}");
      return false;
    }
  }

  Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      final result = pin != null && pin.isNotEmpty;
      FlutterBugfender.log("REPO: Read hasPin=$result");
      return result;
    } catch (e) {
      FlutterBugfender.error("REPO ERROR: hasPin failed - ${e.toString()}");
      return false;
    }
  }

  Future<String?> getPin() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      FlutterBugfender.log("REPO: Read getPin=${pin != null}");
      return pin;
    } catch (e) {
      FlutterBugfender.error("REPO ERROR: getPin failed - ${e.toString()}");
      return null;
    }
  }

  // Write operations
  Future<bool> setEnabled(bool enabled) async {
    try {
      await _storage.write(key: _enabledKey, value: enabled.toString());
      FlutterBugfender.log("REPO: Write setEnabled=$enabled");

      // Verify write was successful
      final verification = await _storage.read(key: _enabledKey);
      final success = verification == enabled.toString();

      if (!success) {
        FlutterBugfender.error(
            "REPO ERROR: setEnabled verification failed - expected '${enabled.toString()}' but got '$verification'");
      }

      return success;
    } catch (e) {
      FlutterBugfender.error("REPO ERROR: setEnabled failed - ${e.toString()}");
      return false;
    }
  }

  Future<bool> savePin(String pin) async {
    try {
      await _storage.write(key: _pinKey, value: pin);
      FlutterBugfender.log("REPO: Write savePin (length=${pin.length})");

      // Verify write was successful
      final verification = await _storage.read(key: _pinKey);
      final success = verification == pin;

      if (!success) {
        FlutterBugfender.error("REPO ERROR: savePin verification failed");
      }

      return success;
    } catch (e) {
      FlutterBugfender.error("REPO ERROR: savePin failed - ${e.toString()}");
      return false;
    }
  }

  Future<bool> clearPin() async {
    try {
      await _storage.delete(key: _pinKey);
      FlutterBugfender.log("REPO: Deleted PIN");
      return true;
    } catch (e) {
      FlutterBugfender.error("REPO ERROR: clearPin failed - ${e.toString()}");
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      await _storage.delete(key: _pinKey);
      await _storage.delete(key: _enabledKey);
      FlutterBugfender.log("REPO: Cleared all PIN data");
      return true;
    } catch (e) {
      FlutterBugfender.error("REPO ERROR: clearAll failed - ${e.toString()}");
      return false;
    }
  }

  // Verification
  Future<bool> verifyPin(String inputPin) async {
    try {
      final storedPin = await getPin();
      final isCorrect = storedPin == inputPin;
      FlutterBugfender.log("REPO: verifyPin result=$isCorrect");
      return isCorrect;
    } catch (e) {
      FlutterBugfender.error("REPO ERROR: verifyPin failed - ${e.toString()}");
      return false;
    }
  }
}
