import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/core/models/haptic_feedback_settings_model.dart';

class HapticFeedbackSettingsProvider with ChangeNotifier {
  static const String _keyPrefix = 'haptic_feedback_settings_';
  static const String _navigationEnabledKey = '${_keyPrefix}navigation_enabled';
  static const String _buttonEnabledKey = '${_keyPrefix}button_enabled';
  static const String _gestureEnabledKey = '${_keyPrefix}gesture_enabled';
  static const String _intensityKey = '${_keyPrefix}intensity';

  HapticFeedbackSettingsModel _settings = const HapticFeedbackSettingsModel();

  HapticFeedbackSettingsModel get settings => _settings;

  HapticFeedbackSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final navigationEnabled = prefs.getBool(_navigationEnabledKey) ?? true;
      final buttonEnabled = prefs.getBool(_buttonEnabledKey) ?? true;
      final gestureEnabled = prefs.getBool(_gestureEnabledKey) ?? true;
      final intensityName = prefs.getString(_intensityKey);
      final intensity = intensityName != null
          ? HapticFeedbackIntensity.values.firstWhere(
              (e) => e.name == intensityName,
              orElse: () => HapticFeedbackIntensity.medium,
            )
          : HapticFeedbackIntensity.medium;

      _settings = HapticFeedbackSettingsModel(
        navigationEnabled: navigationEnabled,
        buttonEnabled: buttonEnabled,
        gestureEnabled: gestureEnabled,
        intensity: intensity,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load haptic feedback settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_navigationEnabledKey, _settings.navigationEnabled);
      await prefs.setBool(_buttonEnabledKey, _settings.buttonEnabled);
      await prefs.setBool(_gestureEnabledKey, _settings.gestureEnabled);
      await prefs.setString(_intensityKey, _settings.intensity.name);
    } catch (e) {
      debugPrint('Failed to save haptic feedback settings: $e');
    }
  }

  Future<void> updateNavigationEnabled(bool enabled) async {
    try {
      _settings = _settings.copyWith(navigationEnabled: enabled);
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update navigation haptic feedback: $e');
    }
  }

  Future<void> updateButtonEnabled(bool enabled) async {
    try {
      _settings = _settings.copyWith(buttonEnabled: enabled);
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update button haptic feedback: $e');
    }
  }

  Future<void> updateGestureEnabled(bool enabled) async {
    try {
      _settings = _settings.copyWith(gestureEnabled: enabled);
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update gesture haptic feedback: $e');
    }
  }

  Future<void> updateIntensity(HapticFeedbackIntensity intensity) async {
    try {
      _settings = _settings.copyWith(intensity: intensity);
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update haptic feedback intensity: $e');
    }
  }

  // Helper methods to trigger haptic feedback
  void triggerNavigationHaptic() {
    if (_settings.navigationEnabled) {
      _triggerHaptic();
    }
  }

  void triggerButtonHaptic() {
    if (_settings.buttonEnabled) {
      _triggerHaptic();
    }
  }

  void triggerGestureHaptic() {
    if (_settings.gestureEnabled) {
      _triggerHaptic();
    }
  }

  void _triggerHaptic() {
    switch (_settings.intensity) {
      case HapticFeedbackIntensity.light:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackIntensity.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackIntensity.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }
}
