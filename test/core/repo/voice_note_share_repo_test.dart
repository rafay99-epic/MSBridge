import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Code under test
import 'package:msbridge/core/repo/voice_note_share_repo.dart';
// Voice note model (fields used in validation tests)
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String boxName = 'voice_note_share_meta';

  setUpAll(() async {
    // Initialize Hive for a temporary directory to avoid touching real device storage.
    final dir = Directory.systemTemp.createTempSync('vn_share_repo_test_');
    // HiveFlutter exports Hive from hive; initFlutter will set up a default path using path_provider.
    // On headless tests, prefer plain Hive.init on a temp dir to avoid platform channels.
    Hive.init(dir.path);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).clear();
      await Hive.box(boxName).close();
    }
  });

  tearDownAll(() async {
    // Close any remaining boxes and delete from disk
      for (final name in Hive.boxNames.toList()) {
      final b = Hive.box(name);
      await b.clear();
      await b.close();
    }
  });

  group('VoiceNoteShareRepository.getSharedVoiceNotes', () {
    test('returns empty list when box empty', () async {
      final box = await Hive.openBox(boxName);
      expect(box.isEmpty, isTrue);

      final result = await VoiceNoteShareRepository.getSharedVoiceNotes();
      expect(result, isEmpty);
    });

    test('filters out disabled entries and sorts by title (case-insensitive)', () async {
      final box = await Hive.openBox(boxName);

      // Mix of enabled/disabled with varying title cases
      await box.put('idA', {
        'shareId': 'S1',
        'enabled': true,
        'shareUrl': 'https://x/y1',
        'title': 'alpha', // lower
        'audioUrl': 'https://cdn/a1.mp3',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await box.put('idB', {
        'shareId': 'S2',
        'enabled': false, // should be filtered out
        'shareUrl': 'https://x/y2',
        'title': 'bravo',
        'audioUrl': 'https://cdn/a2.mp3',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await box.put('idC', {
        'shareId': 'S3',
        'enabled': true,
        'shareUrl': 'https://x/y3',
        'title': 'CHARLIE', // upper
        'audioUrl': 'https://cdn/a3.mp3',
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await box.put('idD', {
        'shareId': 'S4',
        'enabled': true,
        'shareUrl': 'https://x/y4',
        'title': 'Bravo', // mixed
        'audioUrl': 'https://cdn/a4.mp3',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final result = await VoiceNoteShareRepository.getSharedVoiceNotes();

      // Should include only idA, idC, idD (enabled), sorted by title case-insensitively:
      // alpha, Bravo, CHARLIE -> alpha, Bravo, CHARLIE
      expect(result.length, 3);

      expect(result[0].voiceNoteId, 'idA');
      expect(result[0].shareId, 'S1');
      expect(result[0].shareUrl, 'https://x/y1');
      expect(result[0].title, 'alpha');
      expect(result[0].audioUrl, 'https://cdn/a1.mp3');

      expect(result[1].voiceNoteId, 'idD'); // "Bravo" should come before "CHARLIE"
      expect(result[1].title, 'Bravo');

      expect(result[2].voiceNoteId, 'idC');
      expect(result[2].title, 'CHARLIE');
    });

    test('tolerates missing optional fields by coercing to defaults', () async {
      final box = await Hive.openBox(boxName);
      await box.put('idE', {
        'enabled': true,
        // Missing shareId/shareUrl/title/audioUrl should become empty strings
      });

      final result = await VoiceNoteShareRepository.getSharedVoiceNotes();
      expect(result.length, 1);
      final m = result.first;
      expect(m.voiceNoteId, 'idE');
      expect(m.shareId, '');
      expect(m.shareUrl, '');
      expect(m.title, '');
      expect(m.audioUrl, '');
    });
  });

  group('VoiceNoteShareRepository.getShareStatus', () {
    test('returns disabled default when no data found', () async {
      await Hive.openBox(boxName); // ensure box exists but empty
      final status = await VoiceNoteShareRepository.getShareStatus('unknown-id');

      expect(status.enabled, isFalse);
      expect(status.shareUrl, isEmpty);
      expect(status.shareId, isEmpty);
      expect(status.audioUrl, isEmpty);
    });

    test('returns populated status when data present', () async {
      final box = await Hive.openBox(boxName);
      await box.put('idZ', {
        'enabled': true,
        'shareUrl': 'https://s/url',
        'shareId': 'SHARE123',
        'audioUrl': 'https://cdn/a.mp3',
      });

      final status = await VoiceNoteShareRepository.getShareStatus('idZ');

      expect(status.enabled, isTrue);
      expect(status.shareUrl, 'https://s/url');
      expect(status.shareId, 'SHARE123');
      expect(status.audioUrl, 'https://cdn/a.mp3');
    });

    test('coerces nulls and missing keys to defaults', () async {
      final box = await Hive.openBox(boxName);
      await box.put('idY', {
        // enabled missing -> false
        'shareUrl': null, // -> ''
        // shareId missing -> ''
        'audioUrl': null, // -> ''
      });

      final status = await VoiceNoteShareRepository.getShareStatus('idY');

      expect(status.enabled, isFalse);
      expect(status.shareUrl, '');
      expect(status.shareId, '');
      expect(status.audioUrl, '');
    });
  });

  group('VoiceNoteShareRepository.enableShare validation', () {
    // These tests intentionally avoid Firebase by checking early validation branches.
    test('throws when voiceNoteId is null', () async {
      final model = VoiceNoteModel(
        voiceNoteId: null,
        voiceNoteTitle: 'Title',
        description: 'desc',
        audioFilePath: '/tmp/audio.mp3',
        durationInSeconds: 10,
        fileSizeInBytes: 1234,
      );

      expect(
        () => VoiceNoteShareRepository.enableShare(model),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Voice note must be saved before sharing.'),
        )),
      );
    });

    test('throws when voiceNoteId is empty', () async {
      final model = VoiceNoteModel(
        voiceNoteId: '',
        voiceNoteTitle: 'Title',
        description: 'desc',
        audioFilePath: '/tmp/audio.mp3',
        durationInSeconds: 10,
        fileSizeInBytes: 1234,
      );

      expect(
        () => VoiceNoteShareRepository.enableShare(model),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Voice note must be saved before sharing.'),
        )),
      );
    });
  });
}