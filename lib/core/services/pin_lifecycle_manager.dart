import 'package:flutter/widgets.dart';
import 'package:msbridge/core/provider/app_pin_lock_provider.dart';

/// Manages PIN lock lifecycle and ensures PIN lock is always active when needed
class PinLifecycleManager with WidgetsBindingObserver {
  final AppPinLockProvider _pinProvider;
  DateTime? _lastBackgroundTime;
  bool _isAppInBackground = false;

  PinLifecycleManager(this._pinProvider) {
    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove observer when manager is disposed
    WidgetsBinding.instance.removeObserver(this);
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
    _isAppInBackground = true;
    _lastBackgroundTime = DateTime.now();
    _logLifecycleEvent('app_paused');
  }

  void _handleAppResumed() {
    _isAppInBackground = false;

    // Always refresh PIN lock state when app resumes
    _refreshPinLockState();

    _logLifecycleEvent('app_resumed');
  }

  void _handleAppDetached() {
    _isAppInBackground = true;
    _logLifecycleEvent('app_detached');
  }

  void _handleAppInactive() {
    _logLifecycleEvent('app_inactive');
  }

  void _handleAppHidden() {
    _isAppInBackground = true;
    _logLifecycleEvent('app_hidden');
  }

  /// Refresh PIN lock state from secure storage
  Future<void> _refreshPinLockState() async {
    try {
      await _pinProvider.refreshPinLockState();
    } catch (e) {
      // Log error but don't break the app
      print('Failed to refresh PIN lock state: $e');
    }
  }

  /// Check if app was recently in background
  bool get wasRecentlyInBackground => _lastBackgroundTime != null;

  /// Get background duration
  Duration? get backgroundDuration {
    if (_lastBackgroundTime == null) return null;
    return DateTime.now().difference(_lastBackgroundTime!);
  }

  /// Check if PIN lock should be shown
  Future<bool> shouldShowPinLock() async {
    return await _pinProvider.shouldShowPinLock();
  }

  void _logLifecycleEvent(String event) {
    // Simple logging for debugging
    print('PIN Lifecycle: $event - Background: $_isAppInBackground');
  }
}
