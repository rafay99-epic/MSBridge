import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AppPinLockProvider extends ChangeNotifier with WidgetsBindingObserver {
  static const _storage = FlutterSecureStorage();
  static const String _pinKey = 'app_pin_lock_code';
  static const String _enabledKey = 'app_pin_lock_enabled';

  bool _enabled = false;
  bool get enabled => _enabled;

  // Background state tracking
  DateTime? _lastBackgroundTime;
  bool get wasRecentlyInBackground => _lastBackgroundTime != null;

  // Error handling
  String? _lastError;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;

  AppPinLockProvider() {
    _load();
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove observer when provider is disposed
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
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  void _handleAppPaused() {
    _lastBackgroundTime = DateTime.now();
    logCustomEvent('app_paused', parameters: {
      'timestamp': _lastBackgroundTime!.toIso8601String(),
      'pin_enabled': _enabled
    });
  }

  void _handleAppResumed() {
    // Always refresh PIN lock state when app resumes
    _refreshPinLockState();

    logCustomEvent('app_resumed', parameters: {
      'was_in_background': _lastBackgroundTime != null,
      'background_duration_ms': _lastBackgroundTime != null
          ? DateTime.now().difference(_lastBackgroundTime!).inMilliseconds
          : 0,
      'pin_enabled': _enabled
    });

    notifyListeners();
  }

  void _handleAppDetached() {
    logCustomEvent('app_detached', parameters: {'pin_enabled': _enabled});
  }

  void _handleAppInactive() {
    logCustomEvent('app_inactive', parameters: {'pin_enabled': _enabled});
  }

  void _handleAppHidden() {
    logCustomEvent('app_hidden', parameters: {'pin_enabled': _enabled});
  }

  /// Refresh PIN lock state from secure storage
  Future<void> _refreshPinLockState() async {
    try {
      final storedEnabled = await _storage.read(key: _enabledKey);
      final newEnabled = storedEnabled == 'true';

      // Always refresh the state when app resumes, regardless of change
      if (newEnabled != _enabled) {
        _enabled = newEnabled;
        logCustomEvent('pin_state_refreshed', parameters: {
          'new_state': newEnabled,
          'was_in_background': _lastBackgroundTime != null
        });
      }

      _clearError();
    } catch (e) {
      _setError('Failed to refresh PIN lock state: ${e.toString()}');
      logNonFatalError('Failed to refresh PIN lock state',
          context: e.toString());
    }
  }

  /// Force refresh PIN lock state from storage (public method)
  Future<void> refreshPinLockState() async {
    await _refreshPinLockState();
    notifyListeners();
  }

  /// Clear background time when PIN verification is successful
  /// This prevents the "incorrect password" bug after app resume
  void onPinVerificationSuccess() {
    _lastBackgroundTime = null;
    logCustomEvent('pin_verification_success',
        parameters: {'background_time_cleared': true});
  }

  /// Get background duration for debugging
  Duration? get backgroundDuration {
    if (_lastBackgroundTime == null) return null;
    return DateTime.now().difference(_lastBackgroundTime!);
  }

  /// Check if PIN lock should be active (enabled + has PIN)
  Future<bool> shouldShowPinLock() async {
    if (!_enabled) return false;
    return await hasPin();
  }

  Future<void> _load() async {
    try {
      final en = await _storage.read(key: _enabledKey);
      _enabled = en == 'true';
      _clearError();
      logCustomEvent('provider_initialized', parameters: {'enabled': _enabled});
      setCrashlyticsUserProperties();
      notifyListeners();
    } catch (e) {
      _enabled = false;
      _setError('Failed to load PIN lock status: ${e.toString()}');
      logNonFatalError('Failed to load PIN lock status', context: e.toString());
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    try {
      _enabled = value;
      await _storage.write(key: _enabledKey, value: value.toString());
      _clearError();
      logCustomEvent('pin_lock_enabled_changed',
          parameters: {'enabled': value});
      setCrashlyticsUserProperties();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update PIN lock status: ${e.toString()}');
      logNonFatalError('Failed to update PIN lock status',
          context: e.toString());
      notifyListeners();
    }
  }

  Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      final hasPin = (pin != null && pin.isNotEmpty);
      _clearError();
      logCustomEvent('pin_status_checked', parameters: {'has_pin': hasPin});
      return hasPin;
    } catch (e) {
      _setError('Failed to check PIN status: ${e.toString()}');
      logNonFatalError('Failed to check PIN status', context: e.toString());
      return false;
    }
  }

  Future<void> savePin(String pin) async {
    try {
      await _storage.write(key: _pinKey, value: pin);
      _clearError();
      logCustomEvent('pin_saved', parameters: {'pin_length': pin.length});
      setCrashlyticsUserProperties();
      notifyListeners();
    } catch (e) {
      _setError('Failed to save PIN: ${e.toString()}');
      logNonFatalError('Failed to save PIN', context: e.toString());
      notifyListeners();
    }
  }

  Future<void> updatePin(String newPin) async {
    try {
      await _storage.write(key: _pinKey, value: newPin);
      _clearError();
      logCustomEvent('pin_updated',
          parameters: {'new_pin_length': newPin.length});
      setCrashlyticsUserProperties();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update PIN: ${e.toString()}');
      logNonFatalError('Failed to update PIN', context: e.toString());
      notifyListeners();
    }
  }

  Future<String?> readPin() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      _clearError();
      logCustomEvent('pin_read', parameters: {'pin_exists': pin != null});
      return pin;
    } catch (e) {
      _setError('Failed to read PIN: ${e.toString()}');
      logNonFatalError('Failed to read PIN', context: e.toString());
      return null;
    }
  }

  Future<void> clearPin() async {
    try {
      await _storage.delete(key: _pinKey);
      await _storage.delete(key: _enabledKey);
      _enabled = false;
      _clearError();
      logCustomEvent('pin_cleared');
      setCrashlyticsUserProperties();
      notifyListeners();
    } catch (e) {
      _setError('Failed to clear PIN: ${e.toString()}');
      logNonFatalError('Failed to clear PIN', context: e.toString());
      notifyListeners();
    }
  }

  // Error handling methods
  void _setError(String error) {
    _lastError = error;

    // Report error to Firebase Crashlytics for production monitoring
    try {
      FirebaseCrashlytics.instance.recordError(
        Exception(error),
        StackTrace.current,
        reason: 'PIN Lock Provider Error',
        information: [
          'Error: $error',
          'Provider: AppPinLockProvider',
          'Timestamp: ${DateTime.now().toIso8601String()}',
        ],
      );
    } catch (e) {
      // If Crashlytics fails, we don't want to break the app
      // This is a fallback to ensure the app continues to function
    }
  }

  void _clearError() {
    _lastError = null;
  }

  // Public method to clear errors manually
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Method to get formatted error message for UI
  String getErrorMessage() {
    if (_lastError == null) return '';

    // Format error message for user display
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
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // Method to check if operation was successful
  bool get isOperationSuccessful => !hasError;

  // Method to reset provider state (useful for testing or error recovery)
  Future<void> reset() async {
    try {
      _enabled = false;
      _clearError();
      await _storage.delete(key: _pinKey);
      await _storage.delete(key: _enabledKey);
      notifyListeners();
    } catch (e) {
      _setError('Failed to reset PIN lock provider: ${e.toString()}');
      notifyListeners();
    }
  }

  // Log non-fatal errors to Crashlytics
  void logNonFatalError(String error, {String? context}) {
    try {
      FirebaseCrashlytics.instance.recordError(
        Exception(error),
        StackTrace.current,
        reason: 'PIN Lock Provider Non-Fatal Error',
        information: [
          'Error: $error',
          'Context: ${context ?? 'No context provided'}',
          'Provider: AppPinLockProvider',
          'Timestamp: ${DateTime.now().toIso8601String()}',
        ],
        fatal: false,
      );
    } catch (e) {
      // Fallback if Crashlytics fails
    }
  }

  // Log custom events to Crashlytics for analytics
  void logCustomEvent(String eventName, {Map<String, dynamic>? parameters}) {
    try {
      FirebaseCrashlytics.instance.log('PIN Lock Provider Event: $eventName');
      if (parameters != null) {
        FirebaseCrashlytics.instance
            .setCustomKey('event_$eventName', parameters.toString());
      }
    } catch (e) {
      // Fallback if Crashlytics fails
    }
  }

  // Method to set custom user properties in Crashlytics
  void setCrashlyticsUserProperties() {
    try {
      FirebaseCrashlytics.instance.setCustomKey('pin_lock_enabled', _enabled);
      FirebaseCrashlytics.instance.setCustomKey('has_pin', _enabled);
      FirebaseCrashlytics.instance
          .setCustomKey('last_error', _lastError ?? 'none');
    } catch (e) {
      // Fallback if Crashlytics fails
    }
  }
}
