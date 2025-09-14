// Tests for VoiceNoteModel
// Testing library/framework: Prefer package:test. If this is a Flutter project, these tests also work under flutter_test (which re-exports 'test').
// Keep tests pure; no Hive box I/O needed.

import 'package:flutter_test/flutter_test.dart' show expect, group, setUp, tearDown, test, isA, throwsA, closeTo;
import 'package:collection/collection.dart';
import 'package:meta/meta.dart' show visibleForTesting;

// Adjust the import path to the actual model location if different in this repo.
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart' as model;
// If the project does not use package: imports, switch to relative:
// import '../../../lib/core/database/voice_notes/voice_note_model.dart' as model;

void main() {
  group('VoiceNoteModel - constructor defaults and basic fields', () {
    test('defaults: createdAt/updatedAt set near now; booleans and lists default as expected', () {
      final before = DateTime.now();
      final m = model.VoiceNoteModel(
        voiceNoteTitle: 'Meeting Notes',
        audioFilePath: '/storage/emulated/0/recordings/meet1.m4a',
        durationInSeconds: 61,
        fileSizeInBytes: 1536,
        userId: 'user-123',
      );
      final after = DateTime.now();

      // Timestamps within interval
      expect(m.createdAt.isAfter(before.subtract(const Duration(seconds: 1))) && m.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      expect(m.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))) && m.updatedAt.isBefore(after.add(const Duration(seconds: 1))), true);

      // Defaults
      expect(m.isSynced, false);
      expect(m.isDeleted, false);
      expect(m.isDeletionSynced, false);
      expect(m.versionNumber, 1);
      expect(m.tags, isA<List<String>>());
      expect(m.tags.isEmpty, true);

      // Required fields preserved
      expect(m.voiceNoteTitle, 'Meeting Notes');
      expect(m.audioFilePath, '/storage/emulated/0/recordings/meet1.m4a');
      expect(m.userId, 'user-123');
    });

    test('allows nullable optionals (voiceNoteId, description, deletedAt, deletedBy, deviceId, lastSyncAt)', () {
      final m = model.VoiceNoteModel(
        voiceNoteTitle: 'T',
        audioFilePath: '/a/b/c.mp3',
        durationInSeconds: 0,
        fileSizeInBytes: 0,
        userId: 'u',
      );
      expect(m.voiceNoteId, null);
      expect(m.description, null);
      expect(m.deletedAt, null);
      expect(m.deletedBy, null);
      expect(m.deviceId, null);
      expect(m.lastSyncAt, null);
    });
  });

  group('VoiceNoteModel - formattedDuration', () {
    test('00:00 for 0 seconds', () {
      final m = _base(durationInSeconds: 0);
      expect(m.formattedDuration, '00:00');
    });
    test('01:01 for 61 seconds', () {
      final m = _base(durationInSeconds: 61);
      expect(m.formattedDuration, '01:01');
    });
    test('59:59 upper minute boundary', () {
      final m = _base(durationInSeconds: 3599);
      expect(m.formattedDuration, '59:59');
    });
  });

  group('VoiceNoteModel - formattedFileSize', () {
    test('< 1024 bytes shows B', () {
      final m = _base(fileSizeInBytes: 500);
      expect(m.formattedFileSize, '500B');
    });
    test('exactly 1024 bytes shows 1.0KB', () {
      final m = _base(fileSizeInBytes: 1024);
      expect(m.formattedFileSize, '1.0KB');
    });
    test('1536 bytes shows 1.5KB', () {
      final m = _base(fileSizeInBytes: 1536);
      expect(m.formattedFileSize, '1.5KB');
    });
    test('1 MB boundary shows 1.0MB', () {
      final m = _base(fileSizeInBytes: 1024 * 1024);
      expect(m.formattedFileSize, '1.0MB');
    });
    test('1.5 MB shows 1.5MB', () {
      final m = _base(fileSizeInBytes: 1024 * 1024 + 512 * 1024);
      expect(m.formattedFileSize, '1.5MB');
    });
  });

  group('VoiceNoteModel - fileName', () {
    test('extracts last segment from Unix-style path', () {
      final m = _base(audioFilePath: '/storage/audio/folder/test.mp3');
      expect(m.fileName, 'test.mp3');
    });
    test('returns whole string if no slash', () {
      final m = _base(audioFilePath: 'solo.wav');
      expect(m.fileName, 'solo.wav');
    });
  });

  group('VoiceNoteModel - copyWith', () {
    test('updates provided fields and preserves others', () {
      final original = _base(
        voiceNoteId: 'id-1',
        voiceNoteTitle: 'Original',
        audioFilePath: '/p/orig.mp3',
        durationInSeconds: 120,
        fileSizeInBytes: 999,
        userId: 'userA',
        tags: ['x'],
        isSynced: false,
        isDeleted: false,
        versionNumber: 1,
      );

      final updated = original.copyWith(
        voiceNoteTitle: 'Updated',
        durationInSeconds: 180,
        isSynced: true,
        tags: ['x', 'y'],
        versionNumber: 2,
      );

      expect(updated.voiceNoteId, 'id-1');
      expect(updated.voiceNoteTitle, 'Updated');
      expect(updated.audioFilePath, '/p/orig.mp3');
      expect(updated.durationInSeconds, 180);
      expect(updated.fileSizeInBytes, 999);
      expect(updated.userId, 'userA');
      expect(updated.isSynced, true);
      expect(updated.isDeleted, false);
      expect(const ListEquality().equals(updated.tags, ['x', 'y']), true);
      expect(updated.versionNumber, 2);
    });

    test('when field not supplied, preserves same reference for tags list', () {
      final original = _base(tags: ['a']);
      final copy = original.copyWith();
      // Implementation uses tags ?? this.tags, so the same list reference is preserved when not overridden.
      expect(identical(original.tags, copy.tags), true);
      expect(const ListEquality().equals(copy.tags, ['a']), true);
    });
  });

  group('VoiceNoteModel - toMap', () {
    test('serializes to expected Map with ISO-8601 dates', () {
      final created = DateTime.utc(2023, 1, 2, 3, 4, 5);
      final updated = DateTime.utc(2023, 2, 3, 4, 5, 6);
      final deleted = DateTime.utc(2024, 5, 6, 7, 8, 9);
      final lastSync = DateTime.utc(2024, 12, 31, 23, 59, 59);

      final m = model.VoiceNoteModel(
        voiceNoteId: 'id-7',
        voiceNoteTitle: 'Serialize',
        audioFilePath: '/p/file.mp3',
        durationInSeconds: 10,
        fileSizeInBytes: 2000,
        createdAt: created,
        updatedAt: updated,
        userId: 'userZ',
        isSynced: true,
        isDeleted: true,
        tags: ['tag1', 'tag2'],
        description: 'desc',
        deletedAt: deleted,
        deletedBy: 'admin',
        deviceId: 'device-1',
        isDeletionSynced: true,
        lastSyncAt: lastSync,
        versionNumber: 3,
      );

      final map = m.toMap();

      expect(map['voiceNoteId'], 'id-7');
      expect(map['voiceNoteTitle'], 'Serialize');
      expect(map['audioFilePath'], '/p/file.mp3');
      expect(map['durationInSeconds'], 10);
      expect(map['fileSizeInBytes'], 2000);
      expect(map['createdAt'], created.toIso8601String());
      expect(map['updatedAt'], updated.toIso8601String());
      expect(map['userId'], 'userZ');
      expect(map['isSynced'], true);
      expect(map['isDeleted'], true);
      expect(const ListEquality().equals(List<String>.from(map['tags']), ['tag1','tag2']), true);
      expect(map['description'], 'desc');
      expect(map['deletedAt'], deleted.toIso8601String());
      expect(map['deletedBy'], 'admin');
      expect(map['deviceId'], 'device-1');
      expect(map['isDeletionSynced'], true);
      expect(map['lastSyncAt'], lastSync.toIso8601String());
      expect(map['versionNumber'], 3);
    });

    test('serializes nullable DateTimes as null when not set', () {
      final m = _base();
      final map = m.toMap();
      expect(map['deletedAt'], null);
      expect(map['lastSyncAt'], null);
    });
  });

  group('VoiceNoteModel - fromMap', () {
    test('deserializes full Map correctly', () {
      final data = {
        'voiceNoteId': 'id-9',
        'voiceNoteTitle': 'Deserialize',
        'audioFilePath': '/p/a.mp3',
        'durationInSeconds': 90,
        'fileSizeInBytes': 4096,
        'createdAt': DateTime.utc(2022, 5, 6, 7, 8, 9).toIso8601String(),
        'updatedAt': DateTime.utc(2022, 6, 7, 8, 9, 10).toIso8601String(),
        'userId': 'userK',
        'isSynced': true,
        'isDeleted': false,
        'tags': ['one', 'two'],
        'description': 'details',
        'deletedAt': DateTime.utc(2023, 1, 1).toIso8601String(),
        'deletedBy': 'usr',
        'deviceId': 'dev-2',
        'isDeletionSynced': true,
        'lastSyncAt': DateTime.utc(2024, 2, 3, 4, 5, 6).toIso8601String(),
        'versionNumber': 7,
      };

      final m = model.VoiceNoteModel.fromMap(Map<String, dynamic>.from(data));

      expect(m.voiceNoteId, 'id-9');
      expect(m.voiceNoteTitle, 'Deserialize');
      expect(m.audioFilePath, '/p/a.mp3');
      expect(m.durationInSeconds, 90);
      expect(m.fileSizeInBytes, 4096);
      expect(m.createdAt.toIso8601String(), data['createdAt']);
      expect(m.updatedAt.toIso8601String(), data['updatedAt']);
      expect(m.userId, 'userK');
      expect(m.isSynced, true);
      expect(m.isDeleted, false);
      expect(const ListEquality().equals(m.tags, ['one','two']), true);
      expect(m.description, 'details');
      expect(m.deletedAt!.toIso8601String(), data['deletedAt']);
      expect(m.deletedBy, 'usr');
      expect(m.deviceId, 'dev-2');
      expect(m.isDeletionSynced, true);
      expect(m.lastSyncAt!.toIso8601String(), data['lastSyncAt']);
      expect(m.versionNumber, 7);
    });

    test('applies safe defaults when fields are missing', () {
      final before = DateTime.now();
      final m = model.VoiceNoteModel.fromMap({
        // voiceNoteId omitted -> null
        // voiceNoteTitle omitted -> ''
        // audioFilePath omitted -> ''
        // durationInSeconds omitted -> 0
        // fileSizeInBytes omitted -> 0
        // createdAt omitted -> now
        // updatedAt omitted -> now
        // userId omitted -> ''
        // isSynced omitted -> false
        // isDeleted omitted -> false
        // tags omitted -> []
        // description omitted -> null
        // deletedAt omitted -> null
        // deletedBy omitted -> null
        // deviceId omitted -> null
        // isDeletionSynced omitted -> false
        // lastSyncAt omitted -> null
        // versionNumber omitted -> 1
      });

      final after = DateTime.now();

      expect(m.voiceNoteId, null);
      expect(m.voiceNoteTitle, '');
      expect(m.audioFilePath, '');
      expect(m.durationInSeconds, 0);
      expect(m.fileSizeInBytes, 0);
      expect(m.createdAt.isAfter(before.subtract(const Duration(seconds: 1))) && m.createdAt.isBefore(after.add(const Duration(seconds: 1))), true);
      expect(m.updatedAt.isAfter(before.subtract(const Duration(seconds: 1))) && m.updatedAt.isBefore(after.add(const Duration(seconds: 1))), true);
      expect(m.userId, '');
      expect(m.isSynced, false);
      expect(m.isDeleted, false);
      expect(m.tags, isA<List<String>>());
      expect(m.tags.isEmpty, true);
      expect(m.description, null);
      expect(m.deletedAt, null);
      expect(m.deletedBy, null);
      expect(m.deviceId, null);
      expect(m.isDeletionSynced, false);
      expect(m.lastSyncAt, null);
      expect(m.versionNumber, 1);
    });

    test('throws FormatException for invalid createdAt string', () {
      expect(
        () => model.VoiceNoteModel.fromMap({
          'createdAt': 'not-a-date',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for invalid updatedAt string', () {
      expect(
        () => model.VoiceNoteModel.fromMap({
          'updatedAt': 'bad-date',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when tags are not list of strings', () {
      // List<String>.from will throw if elements are not strings.
      expect(
        () => model.VoiceNoteModel.fromMap({'tags': [1, 2]}),
        throwsA(isA<TypeError>()),
      );
    });
  });
}

/// Helper to construct a baseline model with overridable fields.
model.VoiceNoteModel _base({
  String? voiceNoteId,
  String voiceNoteTitle = 't',
  String audioFilePath = '/a/b/c.mp3',
  int durationInSeconds = 0,
  int fileSizeInBytes = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
  String userId = 'u',
  bool isSynced = false,
  bool isDeleted = false,
  List<String>? tags,
  String? description,
  DateTime? deletedAt,
  String? deletedBy,
  String? deviceId,
  bool isDeletionSynced = false,
  DateTime? lastSyncAt,
  int versionNumber = 1,
}) {
  return model.VoiceNoteModel(
    voiceNoteId: voiceNoteId,
    voiceNoteTitle: voiceNoteTitle,
    audioFilePath: audioFilePath,
    durationInSeconds: durationInSeconds,
    fileSizeInBytes: fileSizeInBytes,
    createdAt: createdAt,
    updatedAt: updatedAt,
    userId: userId,
    isSynced: isSynced,
    isDeleted: isDeleted,
    tags: tags,
    description: description,
    deletedAt: deletedAt,
    deletedBy: deletedBy,
    deviceId: deviceId,
    isDeletionSynced: isDeletionSynced,
    lastSyncAt: lastSyncAt,
    versionNumber: versionNumber,
  );
}