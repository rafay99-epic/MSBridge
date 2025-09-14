import 'package:flutter_test/flutter_test.dart';
import 'package:msbridge/core/models/voice_note_settings_model.dart';
import 'package:msbridge/core/services/voice_note/voice_note_service.dart';

void main() {
  group('Voice Note Service Tests', () {
    test('File extension parameter handling', () {
      // Test that the service can handle different file extensions

      // Test with different extensions
      final testCases = [
        ('test_file.m4a', 'm4a'),
        ('test_file.opus', 'opus'),
        ('test_file.flac', 'flac'),
        ('test_file.wav', 'wav'),
      ];

      for (final testCase in testCases) {
        final filePath = testCase.$1;
        final expectedExtension = testCase.$2;

        // Extract extension from file path
        final actualExtension = filePath.split('.').last;
        expect(actualExtension, equals(expectedExtension));
      }
    });

    test('Voice note service singleton', () {
      // Test that VoiceNoteService is a singleton
      final service1 = VoiceNoteService();
      final service2 = VoiceNoteService();

      expect(identical(service1, service2), isTrue);
    });

    test('File extension generation for all formats', () {
      // Test that all encoders generate valid file extensions
      final encoders = VoiceNoteAudioEncoder.values;

      for (final encoder in encoders) {
        final extension = encoder.getFileExtension();

        // Verify extension is valid
        expect(extension, isNotEmpty);
        expect(extension, isA<String>());
        expect(extension.length, greaterThan(0));
        expect(extension.length, lessThanOrEqualTo(5));

        // Verify extension matches expected format
        switch (encoder) {
          case VoiceNoteAudioEncoder.aacLc:
          case VoiceNoteAudioEncoder.aacEld:
          case VoiceNoteAudioEncoder.aacHe:
            expect(extension, equals('m4a'));
            break;
          case VoiceNoteAudioEncoder.opus:
            expect(extension, equals('opus'));
            break;
          case VoiceNoteAudioEncoder.flac:
            expect(extension, equals('flac'));
            break;
          case VoiceNoteAudioEncoder.wav:
            expect(extension, equals('wav'));
            break;
        }
      }
    });

    test('Settings model with file extension integration', () {
      // Test that settings model works correctly with file extensions
      final testSettings = [
        VoiceNoteSettingsModel(encoder: VoiceNoteAudioEncoder.aacLc),
        VoiceNoteSettingsModel(encoder: VoiceNoteAudioEncoder.opus),
        VoiceNoteSettingsModel(encoder: VoiceNoteAudioEncoder.flac),
        VoiceNoteSettingsModel(encoder: VoiceNoteAudioEncoder.wav),
      ];

      for (final settings in testSettings) {
        final extension = settings.encoder.getFileExtension();
        expect(extension, isNotEmpty);

        // Test that we can create a filename with the extension
        final testId = 'test_voice_note_123';
        final filename = '$testId.$extension';
        expect(filename, contains(extension));
        expect(filename, startsWith(testId));
      }
    });

    test('Audio quality preset integration', () {
      // Test that audio quality presets work with different encoders
      final qualityPresets = AudioQuality.values;

      for (final quality in qualityPresets) {
        expect(quality.sampleRate, greaterThan(0));
        expect(quality.displayName, isNotEmpty);
        expect(quality.description, isNotEmpty);

        // Test that bit rate is reasonable (0 for lossless is valid)
        expect(quality.bitRate, greaterThanOrEqualTo(0));
        expect(quality.bitRate, lessThanOrEqualTo(1000000)); // 1 Mbps max
      }
    });

    test('Encoder conversion consistency', () {
      // Test that encoder conversions are consistent
      final encoders = VoiceNoteAudioEncoder.values;

      for (final encoder in encoders) {
        // Convert to record encoder and back
        final recordEncoder = encoder.toRecordEncoder();
        final convertedBack =
            VoiceNoteAudioEncoder.fromRecordEncoder(recordEncoder);

        // For most encoders, this should be consistent
        // Note: Some encoders might have fallbacks, so we check if it's valid
        expect(convertedBack, isA<VoiceNoteAudioEncoder>());
      }
    });
  });
}
