import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:local_auth/local_auth.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FingerprintAuthProvider with ChangeNotifier, WidgetsBindingObserver {
  bool _isFingerprintEnabled = false;
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _fingerprintKey = 'fingerprintEnabled';

  DateTime? _lastBackgroundTime;
  bool get wasRecentlyInBackground => _lastBackgroundTime != null;

  FingerprintAuthProvider() {
    _loadFingerprintStatus();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        _logEvent(
            'app_detached', {'fingerprint_enabled': _isFingerprintEnabled});
        break;
      case AppLifecycleState.inactive:
        _logEvent(
            'app_inactive', {'fingerprint_enabled': _isFingerprintEnabled});
        break;
      case AppLifecycleState.hidden:
        _logEvent('app_hidden', {'fingerprint_enabled': _isFingerprintEnabled});
        break;
    }
  }

  void _handleAppPaused() {
    _lastBackgroundTime = DateTime.now();
    _logEvent('app_paused', {
      'timestamp': _lastBackgroundTime!.toIso8601String(),
      'fingerprint_enabled': _isFingerprintEnabled
    });
  }

  void _handleAppResumed() {
    _refreshFingerprintState();

    final backgroundDurationMs = _lastBackgroundTime != null
        ? DateTime.now().difference(_lastBackgroundTime!).inMilliseconds
        : 0;

    _logEvent('app_resumed', {
      'was_in_background': _lastBackgroundTime != null,
      'background_duration_ms': backgroundDurationMs,
      'fingerprint_enabled': _isFingerprintEnabled
    });

    notifyListeners();
  }

  Future<void> _refreshFingerprintState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newEnabled = prefs.getBool(_fingerprintKey) ?? false;

      FlutterBugfender.log(
          "FINGERPRINT REFRESH: current=$_isFingerprintEnabled, new=$newEnabled");

      if (newEnabled != _isFingerprintEnabled) {
        _isFingerprintEnabled = newEnabled;
        _logEvent('fingerprint_state_refreshed', {
          'new_state': newEnabled,
          'was_in_background': _lastBackgroundTime != null,
          'previous_state': _isFingerprintEnabled
        });
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to refresh fingerprint state: ${e.toString()}',
          StackTrace.current.toString());
    }
  }

  Future<void> refreshFingerprintState() async {
    await _refreshFingerprintState();
    notifyListeners();
  }

  void onFingerprintVerificationSuccess() {
    _lastBackgroundTime = null;
    _logEvent(
        'fingerprint_verification_success', {'background_time_cleared': true});
  }

  Duration? get backgroundDuration {
    if (_lastBackgroundTime == null) return null;
    return DateTime.now().difference(_lastBackgroundTime!);
  }

  bool get isFingerprintEnabled => _isFingerprintEnabled;

  Future<void> _loadFingerprintStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isFingerprintEnabled = prefs.getBool(_fingerprintKey) ?? false;
    _logEvent('provider_initialized', {'enabled': _isFingerprintEnabled});
    notifyListeners();
  }

  Future<void> setFingerprintEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _isFingerprintEnabled = value;
    await prefs.setBool(_fingerprintKey, value);

    if (value) {
      // Disable PIN when fingerprint is enabled
      await _disablePinIfEnabled();
    }

    _logEvent('fingerprint_enabled_changed', {'enabled': value});
    notifyListeners();
  }

  Future<bool> authenticate(BuildContext context) async {
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        CustomSnackBar.show(context, "Device doesn't support biometrics");
        return false;
      }

      List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        CustomSnackBar.show(context, "No biometrics are available.");
        return false;
      }

      // Check if we can go back before starting authentication
      bool canGoBack = Navigator.canPop(context);

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: false, // Changed to false to prevent app closing
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        onFingerprintVerificationSuccess();
        _logEvent('fingerprint_authentication_success');
      } else {
        _logEvent('fingerprint_authentication_failed');

        // If authentication was cancelled and we can go back, go back
        if (canGoBack) {
          Navigator.pop(context);
        }
      }

      return didAuthenticate;
    } catch (e) {
      String errorMessage = "Authentication failed: $e";
      if (e is PlatformException) {
        switch (e.code) {
          case 'AuthenticationCanceled':
            errorMessage = "Authentication canceled by user.";
            // Don't show error for user cancellation, just log it
            _logEvent('fingerprint_authentication_cancelled');
            return false;
          case 'AuthenticationFailed':
            errorMessage = "Authentication failed.";
            break;
          case 'NotEnrolled':
            errorMessage = "No biometrics enrolled on this device.";
            break;
          case 'LockedOut':
            errorMessage = "Too many failed attempts. Biometrics locked out.";
            break;
          case 'PermanentlyLockedOut':
            errorMessage = "Biometrics permanently locked out.";
            break;
          case 'NotAvailable':
            errorMessage = "Biometric authentication is not available.";
            break;
          default:
            errorMessage = "Authentication error: ${e.message}";
            break;
        }
      }
      FlutterBugfender.sendCrash(errorMessage, StackTrace.current.toString());
      CustomSnackBar.show(context, errorMessage);
      _logEvent('fingerprint_authentication_error', {'error': errorMessage});
      return false;
    }
  }

  void _logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    try {
      FlutterBugfender.info("FINGERPRINT EVENT: $eventName");
      if (parameters != null) {
        FlutterBugfender.log(
            "FINGERPRINT EVENT: $eventName with parameters: $parameters");
      } else {
        FlutterBugfender.log("FINGERPRINT EVENT: $eventName");
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          "Failed to log fingerprint event: $eventName", e.toString());
    }
  }

  Future<void> _disablePinIfEnabled() async {
    try {
      // Disable PIN when fingerprint is enabled
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pinEnabled', false);
      FlutterBugfender.log("PIN DISABLED due to fingerprint being enabled");
      _logEvent('pin_disabled_for_fingerprint');
    } catch (e) {
      FlutterBugfender.sendCrash("Failed to disable PIN: ${e.toString()}",
          StackTrace.current.toString());
      FlutterBugfender.error("Failed to disable PIN: ${e.toString()}");
    }
  }
}
