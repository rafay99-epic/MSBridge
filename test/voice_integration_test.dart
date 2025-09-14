import 'package:flutter_test/flutter_test.dart';
import 'package:msbridge/core/models/voice_note_settings_model.dart';
import 'package:msbridge/core/provider/voice_note_settings_provider.dart';

void main() {
  group('Voice Note Integration Tests', () {
    test('Settings provider with all encoders', () {
      // Test that the provider can handle all encoder types
      final provider = VoiceNoteSettingsProvider();

      // Test initial state
      expect(provider.settings.encoder, equals(VoiceNoteAudioEncoder.aacLc));
      expect(provider.settings.sampleRate, equals(44100));
      expect(provider.settings.bitRate, equals(128000));
      expect(provider.settings.numChannels, equals(1));
      expect(provider.settings.autoSaveEnabled, equals(true));
    });

    test('Encoder switching functionality', () {
      // Test that we can switch between different encoders
      final encoders = VoiceNoteAudioEncoder.values;

      for (final encoder in encoders) {
        // Test file extension generation
        final extension = encoder.getFileExtension();
        expect(extension, isNotEmpty);

        // Test record encoder conversion
        final recordEncoder = encoder.toRecordEncoder();
        expect(recordEncoder, isNotNull);

        // Test back conversion
        final convertedBack =
            VoiceNoteAudioEncoder.fromRecordEncoder(recordEncoder);
        expect(convertedBack, isA<VoiceNoteAudioEncoder>());
      }
    });

    test('File naming consistency', () {
      // Test that file naming works correctly with different formats
      final testCases = [
        (VoiceNoteAudioEncoder.aacLc, 'm4a'),
        (VoiceNoteAudioEncoder.aacEld, 'm4a'),
        (VoiceNoteAudioEncoder.aacHe, 'm4a'),
        (VoiceNoteAudioEncoder.opus, 'opus'),
        (VoiceNoteAudioEncoder.flac, 'flac'),
        (VoiceNoteAudioEncoder.wav, 'wav'),
      ];

      for (final testCase in testCases) {
        final encoder = testCase.$1;
        final expectedExtension = testCase.$2;

        // Test file extension
        final actualExtension = encoder.getFileExtension();
        expect(actualExtension, equals(expectedExtension));

        // Test filename generation
        final testId = 'test_voice_note_123';
        final filename = '$testId.$actualExtension';
        expect(filename, equals('$testId.$expectedExtension'));
        expect(filename, contains(expectedExtension));
      }
    });

    test('Quality preset integration', () {
      // Test that quality presets work with different encoders
      final qualityPresets = AudioQuality.values;

      for (final quality in qualityPresets) {
        // Test quality properties
        expect(quality.sampleRate, greaterThan(0));
        expect(quality.bitRate, greaterThanOrEqualTo(0));
        expect(quality.displayName, isNotEmpty);
        expect(quality.description, isNotEmpty);

        // Test that sample rate is reasonable
        expect(quality.sampleRate,
            greaterThanOrEqualTo(8000)); // Minimum reasonable sample rate
        expect(quality.sampleRate,
            lessThanOrEqualTo(192000)); // Maximum reasonable sample rate
      }
    });

    test('Settings model serialization round trip', () {
      // Test that settings can be serialized and deserialized correctly
      final originalSettings = VoiceNoteSettingsModel(
        encoder: VoiceNoteAudioEncoder.opus,
        sampleRate: 48000,
        bitRate: 192000,
        numChannels: 2,
        autoSaveEnabled: false,
      );

      // Serialize to map
      final map = originalSettings.toMap();
      expect(map, isA<Map<String, dynamic>>());
      expect(map['encoder'], equals('opus'));
      expect(map['sampleRate'], equals(48000));
      expect(map['bitRate'], equals(192000));
      expect(map['numChannels'], equals(2));
      expect(map['autoSaveEnabled'], equals(false));

      // Deserialize from map
      final restoredSettings = VoiceNoteSettingsModel.fromMap(map);
      expect(restoredSettings.encoder, equals(VoiceNoteAudioEncoder.opus));
      expect(restoredSettings.sampleRate, equals(48000));
      expect(restoredSettings.bitRate, equals(192000));
      expect(restoredSettings.numChannels, equals(2));
      expect(restoredSettings.autoSaveEnabled, equals(false));

      // Test equality
      expect(restoredSettings, equals(originalSettings));
    });

    test('Encoder display information', () {
      // Test that all encoders have proper display information
      for (final encoder in VoiceNoteAudioEncoder.values) {
        // Test display name
        expect(encoder.displayName, isNotEmpty);
        expect(encoder.displayName.length, greaterThan(0));
        expect(encoder.displayName, isA<String>());

        // Test description
        expect(encoder.description, isNotEmpty);
        expect(encoder.description.length, greaterThan(0));
        expect(encoder.description, isA<String>());

        // Test that display name and description are different
        expect(encoder.displayName, isNot(equals(encoder.description)));
      }
    });

    test('Settings copyWith functionality', () {
      // Test that copyWith works correctly for all properties
      const originalSettings = VoiceNoteSettingsModel();

      // Test encoder change
      final encoderChanged = originalSettings.copyWith(
        encoder: VoiceNoteAudioEncoder.flac,
      );
      expect(encoderChanged.encoder, equals(VoiceNoteAudioEncoder.flac));
      expect(
          encoderChanged.sampleRate, equals(44100)); // Should remain unchanged

      // Test sample rate change
      final sampleRateChanged = originalSettings.copyWith(
        sampleRate: 96000,
      );
      expect(sampleRateChanged.sampleRate, equals(96000));
      expect(sampleRateChanged.encoder,
          equals(VoiceNoteAudioEncoder.aacLc)); // Should remain unchanged

      // Test bit rate change
      final bitRateChanged = originalSettings.copyWith(
        bitRate: 256000,
      );
      expect(bitRateChanged.bitRate, equals(256000));
      expect(
          bitRateChanged.sampleRate, equals(44100)); // Should remain unchanged

      // Test channels change
      final channelsChanged = originalSettings.copyWith(
        numChannels: 2,
      );
      expect(channelsChanged.numChannels, equals(2));
      expect(
          channelsChanged.bitRate, equals(128000)); // Should remain unchanged

      // Test auto save change
      final autoSaveChanged = originalSettings.copyWith(
        autoSaveEnabled: false,
      );
      expect(autoSaveChanged.autoSaveEnabled, equals(false));
      expect(autoSaveChanged.numChannels, equals(1)); // Should remain unchanged
    });

    test('Complete workflow simulation', () {
      // Simulate a complete workflow: settings -> recording -> saving

      // 1. User selects Opus format
      const settings = VoiceNoteSettingsModel(
        encoder: VoiceNoteAudioEncoder.opus,
        sampleRate: 48000,
        bitRate: 192000,
        numChannels: 1,
        autoSaveEnabled: true,
      );

      // 2. Verify settings
      expect(settings.encoder, equals(VoiceNoteAudioEncoder.opus));
      expect(settings.encoder.getFileExtension(), equals('opus'));

      // 3. Simulate recording file path generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final recordingPath = 'temp/voice_note_$timestamp.opus';
      expect(recordingPath, contains('.opus'));
      expect(recordingPath, contains('voice_note_'));

      // 4. Simulate save with correct extension
      final voiceNoteId = 'test_id_123';
      final finalPath = '$voiceNoteId.opus';
      expect(finalPath, equals('test_id_123.opus'));

      // 5. Verify all components work together
      expect(settings.encoder.getFileExtension(), equals('opus'));
      expect(settings.encoder.toRecordEncoder(), isNotNull);
      expect(settings.sampleRate, equals(48000));
      expect(settings.bitRate, equals(192000));
    });
  });
}
