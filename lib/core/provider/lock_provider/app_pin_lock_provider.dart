import 'package:flutter/widgets.dart';
import 'package:flutter_bugfender/flutter_bugfender.dart';
import 'package:msbridge/core/repo/pin_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPinLockProvider extends ChangeNotifier with WidgetsBindingObserver {
  final PinRepository _repository;

  bool _enabled = false;
  bool get enabled => _enabled;

  DateTime? _lastBackgroundTime;
  bool get wasRecentlyInBackground => _lastBackgroundTime != null;

  String? _lastError;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;
  bool get isOperationSuccessful => !hasError;

  DateTime? _lastEnabledTime;

  AppPinLockProvider({PinRepository? repository})
      : _repository = repository ?? PinRepository() {
    _load();
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
        _logEvent('app_detached', {'pin_enabled': _enabled});
        break;
      case AppLifecycleState.inactive:
        _logEvent('app_inactive', {'pin_enabled': _enabled});
        break;
      case AppLifecycleState.hidden:
        _logEvent('app_hidden', {'pin_enabled': _enabled});
        break;
    }
  }

  void _handleAppPaused() {
    _lastBackgroundTime = DateTime.now();
    _logEvent('app_paused', {
      'timestamp': _lastBackgroundTime!.toIso8601String(),
      'pin_enabled': _enabled
    });
  }

  void _handleAppResumed() {
    _refreshPinLockState();

    final backgroundDurationMs = _lastBackgroundTime != null
        ? DateTime.now().difference(_lastBackgroundTime!).inMilliseconds
        : 0;

    _logEvent('app_resumed', {
      'was_in_background': _lastBackgroundTime != null,
      'background_duration_ms': backgroundDurationMs,
      'pin_enabled': _enabled
    });

    notifyListeners();
  }

  Future<void> _refreshPinLockState() async {
    try {
      final newEnabled = await _repository.isPinEnabled();

      FlutterBugfender.log("PIN REFRESH: current=$_enabled, new=$newEnabled");

      if (newEnabled != _enabled) {
        _enabled = newEnabled;
        _logEvent('pin_state_refreshed', {
          'new_state': newEnabled,
          'was_in_background': _lastBackgroundTime != null,
          'previous_state': _enabled
        });
      }
      _clearError();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to refresh PIN lock state: ${e.toString()}',
          StackTrace.current.toString());
      _setError('Failed to refresh PIN lock state: ${e.toString()}');
      _logError('Failed to refresh PIN lock state', e.toString());
    }
  }

  Future<void> refreshPinLockState() async {
    await _refreshPinLockState();
    notifyListeners();
  }

  void onPinVerificationSuccess() {
    _lastBackgroundTime = null;
    _logEvent('pin_verification_success', {'background_time_cleared': true});
  }

  Duration? get backgroundDuration {
    if (_lastBackgroundTime == null) return null;
    return DateTime.now().difference(_lastBackgroundTime!);
  }

  Future<bool> shouldShowPinLock() async {
    if (!_enabled) return false;
    return await hasPin();
  }

  Future<void> _load() async {
    try {
      _enabled = await _repository.isPinEnabled();
      _clearError();
      _logEvent('provider_initialized', {'enabled': _enabled});
      _setCrashlyticsProps();
      notifyListeners();
    } catch (e) {
      FlutterBugfender.sendCrash(
          'Failed to load PIN lock status: ${e.toString()}',
          StackTrace.current.toString());

      _setError('Failed to load PIN lock status: ${e.toString()}');
      _logError('Failed to load PIN lock status', e.toString());
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    try {
      final success = await _repository.setEnabled(value);
      if (success) {
        // Re-read from storage to ensure consistency
        _enabled = await _repository.isPinEnabled();

        if (_enabled) {
          _lastEnabledTime = DateTime.now();
          FlutterBugfender.log(
              "PIN ENABLED at ${_lastEnabledTime!.toIso8601String()}");

          // Disable fingerprint when PIN is enabled
          await _disableFingerprintIfEnabled();
        } else if (_lastEnabledTime != null) {
          final duration = DateTime.now().difference(_lastEnabledTime!);
          FlutterBugfender.log(
              "PIN DISABLED after ${duration.inMinutes} minutes");
        }

        _clearError();
        _logEvent('pin_lock_enabled_changed', {'enabled': _enabled});
        _setCrashlyticsProps();
      } else {
        _setError('Failed to update PIN lock status');
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to update PIN lock status: ${e.toString()}');
      _logError('Failed to update PIN lock status', e.toString());
      notifyListeners();
    }
  }

  Future<bool> hasPin() async {
    try {
      final result = await _repository.hasPin();
      _clearError();
      _logEvent('pin_status_checked', {'has_pin': result});
      return result;
    } catch (e) {
      _setError('Failed to check PIN status: ${e.toString()}');
      _logError('Failed to check PIN status', e.toString());
      return false;
    }
  }

  Future<bool> verifyPin(String inputPin) async {
    try {
      final isCorrect = await _repository.verifyPin(inputPin);
      _clearError();
      if (isCorrect) {
        onPinVerificationSuccess();
      }
      return isCorrect;
    } catch (e) {
      _setError('Failed to verify PIN: ${e.toString()}');
      _logError('Failed to verify PIN', e.toString());
      return false;
    }
  }

  Future<void> savePin(String pin) async {
    try {
      final success = await _repository.savePin(pin);
      if (success) {
        _clearError();
        _logEvent('pin_saved', {'pin_length': pin.length});
        _setCrashlyticsProps();
      } else {
        _setError('Failed to save PIN');
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to save PIN: ${e.toString()}');
      _logError('Failed to save PIN', e.toString());
      notifyListeners();
    }
  }

  Future<void> updatePin(String newPin) async {
    try {
      final success = await _repository.savePin(newPin);
      if (success) {
        _clearError();
        _logEvent('pin_updated', {'new_pin_length': newPin.length});
        _setCrashlyticsProps();
      } else {
        _setError('Failed to update PIN');
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to update PIN: ${e.toString()}');
      _logError('Failed to update PIN', e.toString());
      notifyListeners();
    }
  }

  Future<String?> readPin() async {
    try {
      final pin = await _repository.getPin();
      _clearError();
      _logEvent('pin_read', {'pin_exists': pin != null});
      return pin;
    } catch (e) {
      _setError('Failed to read PIN: ${e.toString()}');
      _logError('Failed to read PIN', e.toString());
      return null;
    }
  }

  Future<void> clearPin() async {
    try {
      final success = await _repository.clearAll();
      if (success) {
        _enabled = false;
        _clearError();
        _logEvent('pin_cleared');
        _setCrashlyticsProps();
      } else {
        _setError('Failed to clear PIN');
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear PIN: ${e.toString()}');
      _logError('Failed to clear PIN', e.toString());
      notifyListeners();
    }
  }

  void _setError(String error) {
    try {
      _lastError = error;
      FlutterBugfender.error("PIN ERROR: $error");
    } catch (e) {
      FlutterBugfender.error("Failed to set error: $error");
    }
  }

  void _clearError() {
    _lastError = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  String getErrorMessage() {
    if (_lastError == null) return '';

    if (_lastError!.contains('Failed to load PIN lock status')) {
      return 'Unable to load PIN lock settings. Please restart the app.';
    } else if (_lastError!.contains('Failed to update PIN lock status')) {
      return 'Unable to update PIN lock status. Please try again.';
    } else if (_lastError!.contains('Failed to check PIN status')) {
      return 'Unable to verify PIN status. Please try again.';
    } else if (_lastError!.contains('Failed to save PIN')) {
      return 'Unable to save PIN. Please try again.';
    } else if (_lastError!.contains('Failed to update PIN')) {
      return 'Unable to update PIN. Please try again.';
    } else if (_lastError!.contains('Failed to read PIN')) {
      return 'Unable to read PIN. Please try again.';
    } else if (_lastError!.contains('Failed to clear PIN')) {
      return 'Unable to clear PIN. Please try again.';
    } else if (_lastError!.contains('Failed to verify PIN')) {
      return 'Unable to verify PIN. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> reset() async {
    try {
      FlutterBugfender.log("PIN RESET called from: ${StackTrace.current}");
      final success = await _repository.clearAll();
      if (success) {
        _enabled = false;
        _clearError();
        _logEvent('pin_reset');
      } else {
        _setError('Failed to reset PIN lock provider');
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset PIN lock provider: ${e.toString()}');
      _logError('Failed to reset PIN lock provider', e.toString());
      notifyListeners();
    }
  }

  Future<void> verifyStorageConsistency() async {
    try {
      final storedEnabled = await _repository.isPinEnabled();
      final hasStoredPin = await _repository.hasPin();

      FlutterBugfender.log("STORAGE CHECK: enabled_stored=$storedEnabled, "
          "enabled_memory=$_enabled, has_pin=$hasStoredPin");

      if (storedEnabled != _enabled) {
        FlutterBugfender.error(
            "STORAGE INCONSISTENCY: Memory and storage disagree on enabled state");
        // Optionally sync states
        _enabled = storedEnabled;
        notifyListeners();
      }
    } catch (e) {
      FlutterBugfender.error("STORAGE CHECK ERROR: ${e.toString()}");
    }
  }

  void _logError(String error, String context) {
    try {
      FlutterBugfender.sendCrash("PIN ERROR: $error", context);
    } catch (e) {
      FlutterBugfender.sendCrash("Failed to log error: $error", e.toString());
    }
  }

  void _logEvent(String eventName, [Map<String, dynamic>? parameters]) {
    try {
      FlutterBugfender.info("PIN EVENT: $eventName");
      if (parameters != null) {
        FlutterBugfender.log(
            "PIN EVENT: $eventName with parameters: $parameters");
      } else {
        FlutterBugfender.log("PIN EVENT: $eventName");
      }
    } catch (e) {
      FlutterBugfender.sendCrash(
          "Failed to log event: $eventName", e.toString());
    }
  }

  void _setCrashlyticsProps() {
    try {
      FlutterBugfender.log("PIN PROPS: enabled=$_enabled, has_error=$hasError");
      if (_lastError != null) {
        FlutterBugfender.log("PIN ERROR: $_lastError");
      }
    } catch (e) {
      _logError('Failed to set Crashlytics properties', e.toString());
    }
  }

  Future<void> _disableFingerprintIfEnabled() async {
    try {
      // Import SharedPreferences to disable fingerprint
      final prefs = await SharedPreferences.getInstance();
      final fingerprintEnabled = prefs.getBool('fingerprintEnabled') ?? false;

      if (fingerprintEnabled) {
        await prefs.setBool('fingerprintEnabled', false);
        FlutterBugfender.log("FINGERPRINT DISABLED due to PIN being enabled");
        _logEvent('fingerprint_disabled_for_pin');
      }
    } catch (e) {
      FlutterBugfender.error("Failed to disable fingerprint: ${e.toString()}");
    }
  }
}
