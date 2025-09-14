// Tests use: flutter_test (WidgetTester). No new dependencies introduced.
// Focus on diff-specific behaviors in VoiceNoteCard:
// - tap handling (InkWell / play button)
// - description visibility based on presence
// - file size and duration chips visible
// - date formatting appears (relative strings like "1h ago"), using current time

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Adjust imports to match actual project structure.
import 'package:app/features/voice_notes/widgets/voice_note_card.dart';
import 'package:app/features/voice_notes/models/voice_note_model.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(body: child),
    );

VoiceNoteModel _note({
  String title = 'Daily recap',
  String? description = 'A brief description of the note',
  Duration duration = const Duration(minutes: 3),
  int fileBytes = 2 * 1024 * 1024,
  DateTime? createdAt,
}) {
  return VoiceNoteModel(
    voiceNoteId: 'note_1',
    voiceNoteTitle: title,
    description: description,
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 2)),
    audioFilePath: '/tmp/unused.aac',
    duration: duration,
    fileSizeBytes: fileBytes,
  );
}

void main() {
  group('VoiceNoteCard', () {
    testWidgets('renders title, chips, and description when present', (tester) async {
      final vn = _note();
      await tester.pumpWidget(_wrap(VoiceNoteCard(voiceNote: vn)));

      expect(find.text(vn.voiceNoteTitle), findsOneWidget);
      // Duration chip text
      expect(find.text(vn.formattedDuration), findsOneWidget);
      // File size chip text
      expect(find.text(vn.formattedFileSize), findsOneWidget);
      // Description appears when provided
      expect(find.text(vn.description\!), findsOneWidget);
    });

    testWidgets('hides description when null or empty', (tester) async {
      final vnEmpty = _note(description: '');
      await tester.pumpWidget(_wrap(VoiceNoteCard(voiceNote: vnEmpty)));
      expect(find.text('Tap to view'), findsOneWidget);
      // Ensure description container not rendered
      expect(find.byType(Text), isNot(findsNothing)); // ensure widget tree rendered
      expect(find.text(''), findsNothing);

      final vnNull = _note(description: null);
      await tester.pumpWidget(_wrap(VoiceNoteCard(voiceNote: vnNull)));
      expect(find.text('Tap to view'), findsOneWidget);
      expect(find.textContaining('brief description'), findsNothing);
    });

    testWidgets('tapping card and play button triggers onTap', (tester) async {
      final vn = _note();
      int tapCount = 0;
      final onTap = () => tapCount++;

      await tester.pumpWidget(_wrap(VoiceNoteCard(voiceNote: vn, onTap: onTap)));

      // Tap anywhere on card (InkWell)
      await tester.tap(find.byType(VoiceNoteCard));
      await tester.pump();
      // Tap play button (nested InkWell)
      final playIcon = find.widgetWithIcon(InkWell, Icons.play_arrow_rounded);
      expect(playIcon, findsOneWidget);
      await tester.tap(playIcon);
      await tester.pump();

      expect(tapCount, 2);
    });

    testWidgets('relative date string appears for recent notes', (tester) async {
      final vn = _note(createdAt: DateTime.now().subtract(const Duration(minutes: 45)));
      await tester.pumpWidget(_wrap(VoiceNoteCard(voiceNote: vn)));

      // Expect something like "45m ago" in the tree.
      expect(find.textContaining('m ago'), findsWidgets);
    });
  });
}