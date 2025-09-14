// Tests use: flutter_test (WidgetTester). No new dependencies introduced.
// These tests focus on the diff-provided behaviors in VoicePlayerWidget:
// - shows loading indicator initially while checking file existence
// - renders main UI when audio file exists (using a temp file)
// - shows not-found error container when audio file does not exist
// - respects showTitle / showMetadata / compact flags
// - wires through onPlay/onPause/onError from child AudioPlayerWidget

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/features/voice_notes/widgets/voice_player_widget.dart';
import 'package:voice_note_kit/player/audio_player_widget.dart';

Widget _wrapWithTheme(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

VoiceNoteModel _makeVoiceNote({
  required String audioPath,
  String title = 'Meeting recap',
  String? description = 'Quick summary of the daily standup and action items.',
  Duration duration = const Duration(minutes: 2, seconds: 30),
  int fileBytes = 1024 * 1024,
  DateTime? createdAt,
}) {
  // Adjust constructor/fields to match VoiceNoteModel in repo.
  return VoiceNoteModel(
    voiceNoteId: 'vn_1',
    voiceNoteTitle: title,
    description: description,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 1)),
    audioFilePath: audioPath,
    durationInSeconds: duration.inSeconds,
    fileSizeInBytes: fileBytes,
    userId: '',
  );
}

Future<File> _createTempFile() async {
  final dir =
      await Directory.systemTemp.createTemp('voice_player_widget_test_');
  final f = File('${dir.path}/sound.aac');
  await f.writeAsBytes(const [0, 1, 2, 3, 4]); // dummy content
  return f;
}

void main() {
  group('VoicePlayerWidget', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final vn = _makeVoiceNote(audioPath: '/non/existent/path.aac');
      await tester.pumpWidget(_wrapWithTheme(VoicePlayerWidget(voiceNote: vn)));
      // Initial frame before async file check resolves should show CircularProgressIndicator.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders main player UI when audio file exists',
        (tester) async {
      final file = await _createTempFile();
      final vn = _makeVoiceNote(audioPath: file.path);

      await tester.pumpWidget(_wrapWithTheme(VoicePlayerWidget(voiceNote: vn)));
      // Allow async file existence check to complete.
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Title should be visible by default.
      expect(find.text(vn.voiceNoteTitle), findsOneWidget);

      // Metadata: duration and date should be present when not compact.
      expect(find.text(vn.formattedDuration), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.storage), findsOneWidget);

      // AudioPlayerWidget should be present.
      expect(find.byType(AudioPlayerWidget), findsOneWidget);
    });

    testWidgets('shows not-found container when audio file is missing',
        (tester) async {
      final vn = _makeVoiceNote(audioPath: '/path/does/not/exist.aac');

      await tester.pumpWidget(_wrapWithTheme(VoicePlayerWidget(voiceNote: vn)));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.text('Audio file not found'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('respects flags: hide title and metadata; compact layout',
        (tester) async {
      final file = await _createTempFile();
      final vn = _makeVoiceNote(audioPath: file.path);

      await tester.pumpWidget(_wrapWithTheme(
        VoicePlayerWidget(
          voiceNote: vn,
          showTitle: false,
          showMetadata: false,
          compact: true,
        ),
      ));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Title hidden
      expect(find.text(vn.voiceNoteTitle), findsNothing);
      // Metadata hidden
      expect(find.text(vn.formattedDuration), findsNothing);
      expect(find.byIcon(Icons.schedule), findsNothing);
      // Still renders AudioPlayerWidget
      expect(find.byType(AudioPlayerWidget), findsOneWidget);
    });

    testWidgets('forwards onPlay/onPause via child AudioPlayerWidget',
        (tester) async {
      final file = await _createTempFile();
      final vn = _makeVoiceNote(audioPath: file.path);

      bool played = false;
      bool paused = false;

      await tester.pumpWidget(_wrapWithTheme(
        VoicePlayerWidget(
          voiceNote: vn,
          onPlay: (_) => played = true,
          onPause: (_) => paused = true,
        ),
      ));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Access the rendered child and invoke callbacks directly to avoid audio stack.
      final finder = find.byType(AudioPlayerWidget);
      expect(finder, findsOneWidget);
      final audio = tester.widget<AudioPlayerWidget>(finder);

      // Trigger play
      audio.onPlay?.call(true);
      expect(played, isTrue);

      // Trigger pause
      audio.onPlay?.call(false);
      expect(paused, isTrue);
    });

    testWidgets('forwards onError and attempts to show snackbar',
        (tester) async {
      final file = await _createTempFile();
      final vn = _makeVoiceNote(audioPath: file.path);

      bool errored = false;

      await tester.pumpWidget(_wrapWithTheme(
        VoicePlayerWidget(
          voiceNote: vn,
          onError: (_) => errored = true,
        ),
      ));
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      final finder = find.byType(AudioPlayerWidget);
      final audio = tester.widget<AudioPlayerWidget>(finder);

      // Trigger error
      audio.onError?.call('Some failure');
      expect(errored, isTrue);

      // We cannot assert CustomSnackBar invocation directly without a hook.
      // If project exposes a snackbar wrapper test key, prefer asserting on it here.
    });
  });
}
