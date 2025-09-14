// Note: Tests use Flutter's flutter_test package with the standard test API.
// Mocking is done using MethodChannel handlers and in-memory filesystem utilities.
// We avoid introducing new dependencies and align with existing test conventions.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:msbridge/core/services/voice_note_service.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const MethodChannel permissionChannel = MethodChannel('flutter.baseflow.com/permissions/methods');

  late Directory tempAppDir;
  late VoiceNoteService service;

  setUp(() async {
    service = VoiceNoteService();
    tempAppDir = await Directory.systemTemp.createTemp('voice_notes_test_');

    // Mock path_provider for application documents directory
    ServicesBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return tempAppDir.path;
        }
        return null;
      },
    );

    // Default: microphone permission denied; tests override as needed
    ServicesBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      permissionChannel,
      (MethodCall call) async {
        switch (call.method) {
          case 'checkPermissionStatus':
            // 1 = granted, 0 = denied, 2 = restricted, 4 = permanentlyDenied (values vary by plugin versions)
            // We default to denied to force request flow.
            return 0;
          case 'requestPermissions':
            // Return a map of permission codes to statuses; 7 (microphone) commonly used.
            // We default to granted for request path unless overridden in a specific test.
            return <int, int>{7: 1};
          default:
            return null;
        }
      },
    );
  });

  tearDown(() async {
    // Clean mocks
    ServicesBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(pathProviderChannel, null);
    ServicesBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(permissionChannel, null);

    // Cleanup temp directory
    try {
      if (await tempAppDir.exists()) {
        await tempAppDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('VoiceNoteService.getVoiceNotesDirectory', () {
    test('creates and returns the voice_notes directory when absent (happy path)', () async {
      final dir = await service.getVoiceNotesDirectory();
      expect(await dir.exists(), isTrue);
      expect(dir.path, equals('${tempAppDir.path}/voice_notes'));
    });

    test('returns existing voice_notes directory without re-creating it', () async {
      final first = await service.getVoiceNotesDirectory();
      expect(await first.exists(), isTrue);

      // Touch a file to ensure persistence
      final marker = File('${first.path}/marker.txt');
      await marker.writeAsString('ok');

      final second = await service.getVoiceNotesDirectory();
      expect(second.path, equals(first.path));
      expect(await File('${second.path}/marker.txt').exists(), isTrue);
    });
  });

  group('VoiceNoteService.requestMicrophonePermission', () {
    test('returns true when already granted', () async {
      // Override to simulate granted at status check
      ServicesBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        permissionChannel,
        (MethodCall call) async {
          if (call.method == 'checkPermissionStatus') return 1; // granted
          return null;
        },
      );

      final ok = await service.requestMicrophonePermission();
      expect(ok, isTrue);
    });

    test('requests permission when denied and returns request result (granted)', () async {
      // Denied on check, granted on request
      ServicesBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        permissionChannel,
        (MethodCall call) async {
          if (call.method == 'checkPermissionStatus') return 0; // denied
          if (call.method == 'requestPermissions') return <int, int>{7: 1}; // granted after request
          return null;
        },
      );

      final ok = await service.requestMicrophonePermission();
      expect(ok, isTrue);
    });

    test('returns false when permanently denied', () async {
      // Simulate permanently denied
      ServicesBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        permissionChannel,
        (MethodCall call) async {
          if (call.method == 'checkPermissionStatus') return 4; // permanently denied
          return null;
        },
      );

      final ok = await service.requestMicrophonePermission();
      expect(ok, isFalse);
    });
  });

  group('VoiceNoteService.audioFileExists', () {
    test('returns true for an existing file path', () async {
      final tempFile = File('${tempAppDir.path}/exists.m4a');
      await tempFile.writeAsBytes(List<int>.filled(3, 1));
      expect(await service.audioFileExists(tempFile.path), isTrue);
    });

    test('returns false for a non-existent file path', () async {
      expect(await service.audioFileExists('${tempAppDir.path}/missing.m4a'), isFalse);
    });
  });

  group('VoiceNoteService.getTotalStorageUsed', () {
    test('sums sizes of files in voice_notes directory', () async {
      final dir = await service.getVoiceNotesDirectory();

      final f1 = File('${dir.path}/a.m4a');
      final f2 = File('${dir.path}/b.m4a');

      await f1.writeAsBytes(List<int>.filled(10, 0)); // 10 bytes
      await f2.writeAsBytes(List<int>.filled(20, 1)); // 20 bytes

      final total = await service.getTotalStorageUsed();
      expect(total, equals(30));
    });

    test('ignores non-file entities', () async {
      final dir = await service.getVoiceNotesDirectory();

      final f = File('${dir.path}/audio.m4a');
      await f.writeAsBytes(List<int>.filled(7, 0));
      await Directory('${dir.path}/subdir').create();

      final total = await service.getTotalStorageUsed();
      expect(total, equals(7));
    });
  });

  group('VoiceNoteService.formatStorageSize', () {
    test('formats bytes under 1KB as B', () {
      expect(service.formatStorageSize(0), '0B');
      expect(service.formatStorageSize(1), '1B');
      expect(service.formatStorageSize(1023), '1023B');
    });

    test('formats bytes under 1MB as KB with 1 decimal', () {
      expect(service.formatStorageSize(1024), '1.0KB');
      expect(service.formatStorageSize(1536), '1.5KB');
      expect(service.formatStorageSize(1048575), '1024.0KB'); // 1MB - 1
    });

    test('formats bytes under 1GB as MB with 1 decimal', () {
      expect(service.formatStorageSize(1048576), '1.0MB'); // 1MB
      expect(service.formatStorageSize(5 * 1024 * 1024), '5.0MB');
    });

    test('formats bytes at and above 1GB as GB with 1 decimal', () {
      expect(service.formatStorageSize(1024 * 1024 * 1024), '1.0GB');
      expect(service.formatStorageSize(3 * 1024 * 1024 * 1024), '3.0GB');
    });
  });

  group('VoiceNoteService.exportVoiceNote', () {
    test('copies existing source file to export path and returns it (happy path)', () async {
      // Prepare source file inside temp app dir
      final source = File('${tempAppDir.path}/src_audio.m4a');
      await source.writeAsBytes(List<int>.filled(4096, 2));

      // Minimal VoiceNoteModel construction: adapt to actual constructor used in project
      final voiceNote = VoiceNoteModel(
        voiceNoteId: 'vn_1',
        voiceNoteTitle: 'Sample',
        audioFilePath: source.path,
        durationInSeconds: 1,
        fileSizeInBytes: await source.length(),
        userId: 'user_1',
        description: 'desc',
        tags: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final exportPath = '${tempAppDir.path}/exported.m4a';
      final resultPath = await service.exportVoiceNote(voiceNote, exportPath);

      expect(resultPath, exportPath);
      expect(await File(exportPath).exists(), isTrue);
      expect(await File(exportPath).length(), await source.length());
    });

    test('throws when source file does not exist', () async {
      final missing = File('${tempAppDir.path}/nope.m4a');

      final voiceNote = VoiceNoteModel(
        voiceNoteId: 'vn_2',
        voiceNoteTitle: 'Missing',
        audioFilePath: missing.path,
        durationInSeconds: 1,
        fileSizeInBytes: 0,
        userId: 'user_1',
        description: null,
        tags: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await expectLater(
        () => service.exportVoiceNote(voiceNote, '${tempAppDir.path}/out.m4a'),
        throwsA(isA<Exception>()),
      );
    });
  });
}