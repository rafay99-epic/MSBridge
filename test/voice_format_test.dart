// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:msbridge/core/models/voice_note_settings_model.dart';

void main() {
  group('Voice Note Format Tests', () {
    test('File extension generation for all encoders', () {
      // Test AAC encoders
      expect(VoiceNoteAudioEncoder.aacLc.getFileExtension(), equals('m4a'));
      expect(VoiceNoteAudioEncoder.aacEld.getFileExtension(), equals('m4a'));
      expect(VoiceNoteAudioEncoder.aacHe.getFileExtension(), equals('m4a'));

      // Test Opus
      expect(VoiceNoteAudioEncoder.opus.getFileExtension(), equals('opus'));

      // Test FLAC
      expect(VoiceNoteAudioEncoder.flac.getFileExtension(), equals('flac'));

      // Test WAV
      expect(VoiceNoteAudioEncoder.wav.getFileExtension(), equals('wav'));
    });

    test('Encoder to Record package conversion', () {
      // Test all encoder conversions
      expect(VoiceNoteAudioEncoder.aacLc.toRecordEncoder().toString(),
          contains('aacLc'));
      expect(VoiceNoteAudioEncoder.aacEld.toRecordEncoder().toString(),
          contains('aacEld'));
      expect(VoiceNoteAudioEncoder.aacHe.toRecordEncoder().toString(),
          contains('aacHe'));
      expect(VoiceNoteAudioEncoder.opus.toRecordEncoder().toString(),
          contains('opus'));
      expect(VoiceNoteAudioEncoder.flac.toRecordEncoder().toString(),
          contains('flac'));
      expect(VoiceNoteAudioEncoder.wav.toRecordEncoder().toString(),
          contains('wav'));
    });

    test('VoiceNoteSettingsModel with different encoders', () {
      // Test default settings
      const defaultSettings = VoiceNoteSettingsModel();
      expect(defaultSettings.encoder, equals(VoiceNoteAudioEncoder.aacLc));
      expect(defaultSettings.sampleRate, equals(44100));
      expect(defaultSettings.bitRate, equals(128000));
      expect(defaultSettings.numChannels, equals(1));
      expect(defaultSettings.autoSaveEnabled, equals(true));

      // Test custom settings
      const customSettings = VoiceNoteSettingsModel(
        encoder: VoiceNoteAudioEncoder.opus,
        sampleRate: 48000,
        bitRate: 192000,
        numChannels: 2,
        autoSaveEnabled: false,
      );

      expect(customSettings.encoder, equals(VoiceNoteAudioEncoder.opus));
      expect(customSettings.sampleRate, equals(48000));
      expect(customSettings.bitRate, equals(192000));
      expect(customSettings.numChannels, equals(2));
      expect(customSettings.autoSaveEnabled, equals(false));
    });

    test('Settings copyWith functionality', () {
      const originalSettings = VoiceNoteSettingsModel();

      final updatedSettings = originalSettings.copyWith(
        encoder: VoiceNoteAudioEncoder.flac,
        sampleRate: 96000,
      );

      expect(updatedSettings.encoder, equals(VoiceNoteAudioEncoder.flac));
      expect(updatedSettings.sampleRate, equals(96000));
      expect(
          updatedSettings.bitRate, equals(128000)); // Should remain unchanged
      expect(updatedSettings.numChannels, equals(1)); // Should remain unchanged
      expect(updatedSettings.autoSaveEnabled,
          equals(true)); // Should remain unchanged
    });

    test('AudioQuality presets', () {
      // Test all quality presets
      expect(AudioQuality.low.sampleRate, equals(22050));
      expect(AudioQuality.low.bitRate, equals(64000));
      expect(AudioQuality.low.displayName, equals('Low Quality'));

      expect(AudioQuality.medium.sampleRate, equals(44100));
      expect(AudioQuality.medium.bitRate, equals(128000));
      expect(AudioQuality.medium.displayName, equals('Medium Quality'));

      expect(AudioQuality.high.sampleRate, equals(48000));
      expect(AudioQuality.high.bitRate, equals(192000));
      expect(AudioQuality.high.displayName, equals('High Quality'));

      expect(AudioQuality.lossless.sampleRate, equals(48000));
      expect(AudioQuality.lossless.bitRate, equals(0));
      expect(AudioQuality.lossless.displayName, equals('Lossless'));
    });

    test('Settings serialization', () {
      const settings = VoiceNoteSettingsModel(
        encoder: VoiceNoteAudioEncoder.opus,
        sampleRate: 48000,
        bitRate: 192000,
        numChannels: 2,
        autoSaveEnabled: false,
      );

      final map = settings.toMap();
      expect(map['encoder'], equals('opus'));
      expect(map['sampleRate'], equals(48000));
      expect(map['bitRate'], equals(192000));
      expect(map['numChannels'], equals(2));
      expect(map['autoSaveEnabled'], equals(false));

      final restoredSettings = VoiceNoteSettingsModel.fromMap(map);
      expect(restoredSettings.encoder, equals(VoiceNoteAudioEncoder.opus));
      expect(restoredSettings.sampleRate, equals(48000));
      expect(restoredSettings.bitRate, equals(192000));
      expect(restoredSettings.numChannels, equals(2));
      expect(restoredSettings.autoSaveEnabled, equals(false));
    });

    test('File extension consistency', () {
      // Ensure all encoders have valid file extensions
      for (final encoder in VoiceNoteAudioEncoder.values) {
        final extension = encoder.getFileExtension();
        expect(extension, isNotEmpty);
        expect(extension, isA<String>());
        expect(extension.length, greaterThan(0));
        expect(extension.length,
            lessThanOrEqualTo(5)); // Reasonable file extension length
      }
    });

    test('Encoder descriptions and display names', () {
      // Test that all encoders have proper descriptions and display names
      for (final encoder in VoiceNoteAudioEncoder.values) {
        expect(encoder.displayName, isNotEmpty);
        expect(encoder.description, isNotEmpty);
        expect(encoder.displayName.length, greaterThan(0));
        expect(encoder.description.length, greaterThan(0));
      }
    });
  });
}
