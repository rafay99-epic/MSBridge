import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msbridge/core/models/voice_note_settings_model.dart';

class VoiceNoteSettingsProvider with ChangeNotifier {
  static const String _keyPrefix = 'voice_note_settings_';
  static const String _encoderKey = '${_keyPrefix}encoder';
  static const String _sampleRateKey = '${_keyPrefix}sample_rate';
  static const String _bitRateKey = '${_keyPrefix}bit_rate';
  static const String _numChannelsKey = '${_keyPrefix}num_channels';
  static const String _autoSaveKey = '${_keyPrefix}auto_save';

  VoiceNoteSettingsModel _settings = const VoiceNoteSettingsModel();

  VoiceNoteSettingsModel get settings => _settings;

  VoiceNoteSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final encoderName = prefs.getString(_encoderKey);
      final encoder = encoderName != null
          ? VoiceNoteAudioEncoder.values.firstWhere(
              (e) => e.name == encoderName,
              orElse: () => VoiceNoteAudioEncoder.aacLc,
            )
          : VoiceNoteAudioEncoder.aacLc;

      final sampleRate = prefs.getInt(_sampleRateKey) ?? 44100;
      final bitRate = prefs.getInt(_bitRateKey) ?? 128000;
      final numChannels = prefs.getInt(_numChannelsKey) ?? 1;
      final autoSaveEnabled = prefs.getBool(_autoSaveKey) ?? true;

      _settings = VoiceNoteSettingsModel(
        encoder: encoder,
        sampleRate: sampleRate,
        bitRate: bitRate,
        numChannels: numChannels,
        autoSaveEnabled: autoSaveEnabled,
      );

      notifyListeners();
    } catch (e) {
      // If loading fails, use default settings
      _settings = const VoiceNoteSettingsModel();
      notifyListeners();
    }
  }

  Future<void> updateEncoder(VoiceNoteAudioEncoder encoder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_encoderKey, encoder.name);

      _settings = _settings.copyWith(encoder: encoder);
      notifyListeners();
    } catch (e) {
      // Handle error silently or log it
      debugPrint('Failed to update encoder: $e');
    }
  }

  Future<void> updateSampleRate(int sampleRate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sampleRateKey, sampleRate);

      _settings = _settings.copyWith(sampleRate: sampleRate);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update sample rate: $e');
    }
  }

  Future<void> updateBitRate(int bitRate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bitRateKey, bitRate);

      _settings = _settings.copyWith(bitRate: bitRate);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update bit rate: $e');
    }
  }

  Future<void> updateNumChannels(int numChannels) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_numChannelsKey, numChannels);

      _settings = _settings.copyWith(numChannels: numChannels);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update num channels: $e');
    }
  }

  Future<void> updateAutoSave(bool autoSaveEnabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoSaveKey, autoSaveEnabled);

      _settings = _settings.copyWith(autoSaveEnabled: autoSaveEnabled);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update auto save: $e');
    }
  }

  Future<void> applyQualityPreset(AudioQuality quality) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update encoder based on quality
      VoiceNoteAudioEncoder encoder;
      switch (quality) {
        case AudioQuality.lossless:
          encoder = VoiceNoteAudioEncoder.flac;
          break;
        default:
          encoder = VoiceNoteAudioEncoder.aacLc;
      }

      await prefs.setString(_encoderKey, encoder.name);
      await prefs.setInt(_sampleRateKey, quality.sampleRate);
      await prefs.setInt(_bitRateKey, quality.bitRate);

      _settings = _settings.copyWith(
        encoder: encoder,
        sampleRate: quality.sampleRate,
        bitRate: quality.bitRate,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to apply quality preset: $e');
    }
  }

  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_encoderKey);
      await prefs.remove(_sampleRateKey);
      await prefs.remove(_bitRateKey);
      await prefs.remove(_numChannelsKey);
      await prefs.remove(_autoSaveKey);

      _settings = const VoiceNoteSettingsModel();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reset to defaults: $e');
    }
  }

  // Helper methods for UI
  VoiceNoteAudioEncoder _getExpectedEncoderForQuality(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.lossless:
        return VoiceNoteAudioEncoder.flac;
      default:
        return VoiceNoteAudioEncoder.aacLc;
    }
  }

  AudioQuality getCurrentQualityPreset() {
    for (final quality in AudioQuality.values) {
      final expectedEncoder = _getExpectedEncoderForQuality(quality);
      if (_settings.sampleRate == quality.sampleRate &&
          _settings.bitRate == quality.bitRate &&
          _settings.encoder == expectedEncoder) {
        return quality;
      }
    }
    return AudioQuality.medium; // Default fallback
  }

  bool isUsingPreset() {
    final currentPreset = getCurrentQualityPreset();
    final expectedEncoder = _getExpectedEncoderForQuality(currentPreset);

    return (currentPreset != AudioQuality.medium ||
            _settings.bitRate != 128000 ||
            _settings.sampleRate != 44100) &&
        _settings.encoder == expectedEncoder;
  }
}
