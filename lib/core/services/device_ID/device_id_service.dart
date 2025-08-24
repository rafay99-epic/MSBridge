import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';

class DeviceIdService {
  static const String _deviceIdKey = 'device_id';
  static String? _cachedDeviceId;

  // Configure secure storage
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Get or generate a unique device ID
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    String? deviceId = await _secureStorage.read(key: _deviceIdKey);

    if (deviceId == null) {
      deviceId = _generateDeviceId();
      try {
        await _secureStorage.write(key: _deviceIdKey, value: deviceId);
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(
          e,
          StackTrace.current,
          reason:
              'Error writing device ID to secure storage and the expection is $e',
        );
      }
    }

    _cachedDeviceId = deviceId;
    return deviceId;
  }

  /// Generate a unique device ID
  static String _generateDeviceId() {
    // Generate a unique ID based on timestamp and random values
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random();
    final random1 = random.nextInt(999999);
    final random2 = random.nextInt(999999);

    // Create a unique identifier
    return 'device_${timestamp}_${random1}_$random2';
  }

  /// Clear cached device ID (useful for testing)
  static void clearCache() {
    _cachedDeviceId = null;
  }

  /// Clear stored device ID from secure storage
  static Future<void> clearStoredDeviceId() async {
    try {
      await _secureStorage.delete(key: _deviceIdKey);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error clearing stored device ID and the expection is $e',
      );
    }

    _cachedDeviceId = null;
  }

  /// Get device info for debugging
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceId = await getDeviceId();

    return {
      'deviceId': deviceId,
      'platform': 'Cross-platform',
      'generatedAt': DateTime.now().toIso8601String(),
      'storageType': 'Flutter Secure Storage',
    };
  }
}
