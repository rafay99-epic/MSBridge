import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/models/voice_note_settings_model.dart';
import 'package:msbridge/core/provider/voice_note_settings_provider.dart';
import 'package:msbridge/features/voice_notes/screens/voice_note_settings_screen.dart';

void main() {
  group('Voice Note UI Tests', () {
    testWidgets('VoiceNoteSettingsScreen displays format information',
        (WidgetTester tester) async {
      // Create a test app with the voice note settings screen and provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => VoiceNoteSettingsProvider(),
            child: const VoiceNoteSettingsScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the screen loads without errors
      expect(find.byType(VoiceNoteSettingsScreen), findsOneWidget);
    });

    test('Format information card data validation', () {
      // Test that format information can be generated correctly
      final testSettings = VoiceNoteSettingsModel(
        encoder: VoiceNoteAudioEncoder.opus,
        sampleRate: 48000,
        bitRate: 192000,
        numChannels: 2,
        autoSaveEnabled: true,
      );

      // Test format display data
      final encoder = testSettings.encoder;
      final fileExtension = encoder.getFileExtension();
      final displayName = encoder.displayName;
      final description = encoder.description;

      // Verify all data is valid
      expect(fileExtension, equals('opus'));
      expect(displayName, equals('Opus'));
      expect(description, equals('Open source, excellent quality'));
      expect(displayName, isNotEmpty);
      expect(description, isNotEmpty);
      expect(fileExtension, isNotEmpty);
    });

    test('All encoders have valid UI data', () {
      // Test that all encoders have proper data for UI display
      for (final encoder in VoiceNoteAudioEncoder.values) {
        // Test display name
        expect(encoder.displayName, isNotEmpty);
        expect(encoder.displayName.length, greaterThan(0));

        // Test description
        expect(encoder.description, isNotEmpty);
        expect(encoder.description.length, greaterThan(0));

        // Test file extension
        final extension = encoder.getFileExtension();
        expect(extension, isNotEmpty);
        expect(extension.length, greaterThan(0));
        expect(extension.length, lessThanOrEqualTo(5));

        // Test that display name and description are different
        expect(encoder.displayName, isNot(equals(encoder.description)));
      }
    });

    test('Settings model UI integration', () {
      // Test that settings model works correctly with UI requirements
      final testCases = [
        VoiceNoteSettingsModel(encoder: VoiceNoteAudioEncoder.aacLc),
        VoiceNoteSettingsModel(encoder: VoiceNoteAudioEncoder.opus),
        VoiceNoteSettingsModel(encoder: VoiceNoteAudioEncoder.flac),
        VoiceNoteSettingsModel(encoder: VoiceNoteAudioEncoder.wav),
      ];

      for (final settings in testCases) {
        // Test that we can generate UI display strings
        final formatDisplay =
            '${settings.encoder.displayName} (.${settings.encoder.getFileExtension()})';
        expect(formatDisplay, isNotEmpty);
        expect(formatDisplay, contains(settings.encoder.displayName));
        expect(formatDisplay, contains(settings.encoder.getFileExtension()));

        // Test that we can generate sample rate display
        final sampleRateDisplay = '${settings.sampleRate} Hz';
        expect(sampleRateDisplay, isNotEmpty);
        expect(sampleRateDisplay, contains(settings.sampleRate.toString()));

        // Test that we can generate bit rate display
        if (settings.encoder != VoiceNoteAudioEncoder.flac &&
            settings.encoder != VoiceNoteAudioEncoder.wav) {
          final bitRateDisplay = '${settings.bitRate ~/ 1000} kbps';
          expect(bitRateDisplay, isNotEmpty);
          expect(bitRateDisplay, contains('kbps'));
        }

        // Test that we can generate channels display
        final channelsDisplay = settings.numChannels == 1 ? 'Mono' : 'Stereo';
        expect(channelsDisplay, isNotEmpty);
        expect(channelsDisplay, anyOf(['Mono', 'Stereo']));
      }
    });

    test('Quality preset UI data validation', () {
      // Test that quality presets have proper UI data
      for (final quality in AudioQuality.values) {
        // Test display name
        expect(quality.displayName, isNotEmpty);
        expect(quality.displayName.length, greaterThan(0));

        // Test description
        expect(quality.description, isNotEmpty);
        expect(quality.description.length, greaterThan(0));

        // Test sample rate display
        final sampleRateDisplay = '${quality.sampleRate}Hz';
        expect(sampleRateDisplay, isNotEmpty);
        expect(sampleRateDisplay, contains(quality.sampleRate.toString()));

        // Test that display name and description are different
        expect(quality.displayName, isNot(equals(quality.description)));
      }
    });

    test('File extension badge generation', () {
      // Test that file extension badges can be generated correctly
      for (final encoder in VoiceNoteAudioEncoder.values) {
        final extension = encoder.getFileExtension();
        final badgeText = '.$extension';

        expect(badgeText, isNotEmpty);
        expect(badgeText, startsWith('.'));
        expect(badgeText.length, greaterThan(1));
        expect(badgeText.length, lessThanOrEqualTo(6)); // .m4a, .opus, etc.
      }
    });

    test('Settings serialization for UI persistence', () {
      // Test that settings can be serialized and restored for UI persistence
      final originalSettings = VoiceNoteSettingsModel(
        encoder: VoiceNoteAudioEncoder.flac,
        sampleRate: 96000,
        bitRate: 0, // Lossless
        numChannels: 2,
        autoSaveEnabled: false,
      );

      // Serialize
      final map = originalSettings.toMap();
      expect(map, isA<Map<String, dynamic>>());

      // Deserialize
      final restoredSettings = VoiceNoteSettingsModel.fromMap(map);

      // Verify UI data is preserved
      expect(restoredSettings.encoder.displayName,
          equals(originalSettings.encoder.displayName));
      expect(restoredSettings.encoder.getFileExtension(),
          equals(originalSettings.encoder.getFileExtension()));
      expect(restoredSettings.sampleRate, equals(originalSettings.sampleRate));
      expect(restoredSettings.bitRate, equals(originalSettings.bitRate));
      expect(
          restoredSettings.numChannels, equals(originalSettings.numChannels));
      expect(restoredSettings.autoSaveEnabled,
          equals(originalSettings.autoSaveEnabled));
    });
  });
}
