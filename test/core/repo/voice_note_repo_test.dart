// Testing library/framework: flutter_test (Flutter SDK) with lightweight in-file fakes (no external mocking libs).
// These tests focus on the diffed VoiceNoteRepo behaviors including error paths and edge cases.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart' as hive_flutter;
import 'package:hive/hive.dart' as hive;
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/repo/voice_note_repo.dart';

// ---- Lightweight fakes and helpers ----

// A minimal fake VoiceNoteModel that exposes only the fields/methods used by VoiceNoteRepo.
class FakeVoiceNoteModel implements VoiceNoteModel {
  @override
  String? voiceNoteId;

  @override
  String voiceNoteTitle;

  @override
  String? description;

  @override
  List<String> tags;

  @override
  String? userId;

  @override
  bool isSynced;

  @override
  DateTime createdAt;

  // Save behavior is controlled via this callback to simulate success/failure.
  Future<void> Function()? onSave;

  FakeVoiceNoteModel({
    required this.voiceNoteId,
    required this.voiceNoteTitle,
    this.description,
    List<String>? tags,
    this.userId,
    this.isSynced = false,
    DateTime? createdAt,
    this.onSave,
  })  : tags = tags ?? <String>[],
        createdAt = createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<void> save() async {
    if (onSave \!= null) {
      await onSave\!();
      return;
    }
    // default is no-op
  }

  // The following members satisfy the interface; if VoiceNoteModel changes,
  // extend stubs accordingly for tests to compile.
  // ignore: unused_element
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// A simple in-memory Box fake with only the methods used by VoiceNoteRepo.
class InMemoryBox<T> implements hive.Box<T> {
  final String name;
  bool _isOpen = true;
  final Map<dynamic, T> _store = {};

  InMemoryBox(this.name);

  // Core methods used
  @override
  Future<void> put(dynamic key, T value) async {
    _store[key] = value;
  }

  @override
  T? get(dynamic key, {T? defaultValue}) {
    return _store.containsKey(key) ? _store[key] : defaultValue;
  }

  @override
  Future<int> clear() async {
    final c = _store.length;
    _store.clear();
    return c;
  }

  @override
  Future<void> delete(dynamic key) async {
    _store.remove(key);
  }

  @override
  Iterable get keys => _store.keys;

  @override
  Iterable<T> get values => _store.values;

  // State
  @override
  bool get isOpen => _isOpen;

  void closeBox() {
    _isOpen = false;
  }

  // Unused members -> noSuchMethod stubs
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Harness to override the global Hive interface used by VoiceNoteRepo.
class FakeHive implements hive.HiveInterface {
  final Map<String, hive.Box> _boxes = {};

  hive.Box<T> registerBox<T>(String name, hive.Box<T> box) {
    _boxes[name] = box;
    return box;
  }

  @override
  Future<hive.Box<E>> openBox<E>(String name, {hive.Cipher? encryptionCipher, List<int>? bytes, String? path, bool crashRecovery = true}) async {
    if (_boxes.containsKey(name)) {
      final bx = _boxes[name] as hive.Box<E>;
      return bx;
    }
    throw Exception('Box "$name" not registered in FakeHive');
  }

  @override
  bool isBoxOpen(String name) => _boxes[name] \!= null;

  @override
  hive.Box<E> box<E>(String name) => _boxes[name] as hive.Box<E>;

  // Unused members -> stubs
  @override
  Future<void> close() async {}

  @override
  Future<void> deleteBoxFromDisk(String name, {String? path}) async {
    _boxes.remove(name);
  }

  @override
  Future<void> deleteFromDisk() async {
    _boxes.clear();
  }

  @override
  Future<void> init(String path) async {}

  @override
  Future<void> initFlutter({String? subDir}) async {}

  @override
  Future<void> resetAdapters() async {}

  @override
  bool get isAdapterNameAvailable => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeHive fakeHive;
  late InMemoryBox<VoiceNoteModel> box;

  setUp(() {
    // Replace global Hive with our fake for both hive and hive_flutter imports.
    // This works because both expose the same global variable `Hive` of type HiveInterface.
    fakeHive = FakeHive();
    box = InMemoryBox<VoiceNoteModel>('voice_notes');
    fakeHive.registerBox<VoiceNoteModel>('voice_notes', box);

    // Assign the global Hive singletons used in the code to our fake.
    hive.Hive = fakeHive;
    hive_flutter.Hive = fakeHive as hive_flutter.HiveInterface;
  });

  tearDown(() async {
    // Clear in-memory state.
    await box.clear();
  });

  group('VoiceNoteRepo.getBox', () {
    test('opens and returns the voice_notes box when not yet open', () async {
      // Start closed by simulating not-open state: our FakeHive returns the registered box on openBox.
      final bx = await VoiceNoteRepo.getBox();
      expect(bx, isA<hive.Box<VoiceNoteModel>>());
      expect(bx.values, isEmpty);
    });

    test('reuses already open box', () async {
      final a = await VoiceNoteRepo.getBox();
      final b = await VoiceNoteRepo.getBox();
      expect(identical(a, b), isTrue);
    });

    test('throws with informative message if Hive.openBox throws', () async {
      // Override openBox to throw: by not registering another box name and temporarily swapping the name constant via wrapper test (we can't).
      // Instead, simulate by replacing FakeHive.openBox to always throw for the expected name.
      final throwingHive = _ThrowingHive();
      hive.Hive = throwingHive;
      hive_flutter.Hive = throwingHive as hive_flutter.HiveInterface;

      expect(
        () async => VoiceNoteRepo.getBox(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Error opening Hive box "voice_notes"'))),
      );
    });
  });

  group('VoiceNoteRepo.addVoiceNote', () {
    test('adds note when voiceNoteId present', () async {
      final note = FakeVoiceNoteModel(
        voiceNoteId: 'id-1',
        voiceNoteTitle: 'Title',
        createdAt: DateTime(2024, 1, 1),
      );
      await VoiceNoteRepo.addVoiceNote(note);
      final stored = box.get('id-1');
      expect(stored, isNotNull);
      expect((stored as FakeVoiceNoteModel).voiceNoteTitle, 'Title');
    });

    test('throws ArgumentError when voiceNoteId is null', () async {
      final note = FakeVoiceNoteModel(
        voiceNoteId: null,
        voiceNoteTitle: 'Missing ID',
      );

      expect(
        () => VoiceNoteRepo.addVoiceNote(note),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('voiceNoteId is required'))),
      );
    });

    test('wraps errors and rethrows with context', () async {
      // Make getBox succeed but put throw -> replace box.put to throw via subclass
      final throwingBox = _ThrowingBox<VoiceNoteModel>('voice_notes');
      (hive.Hive as FakeHive).registerBox<VoiceNoteModel>('voice_notes', throwingBox);
      hive_flutter.Hive = hive.Hive as hive_flutter.HiveInterface;

      final note = FakeVoiceNoteModel(
        voiceNoteId: 'boom',
        voiceNoteTitle: 'x',
      );

      expect(
        () => VoiceNoteRepo.addVoiceNote(note),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Error adding voice note'))),
      );
    });
  });

  group('VoiceNoteRepo.updateVoiceNote', () {
    test('calls save on model', () async {
      var saved = false;
      final note = FakeVoiceNoteModel(
        voiceNoteId: 'u1',
        voiceNoteTitle: 't',
        onSave: () async {
          saved = true;
        },
      );

      await VoiceNoteRepo.updateVoiceNote(note);
      expect(saved, isTrue);
    });

    test('wraps and throws when save fails', () async {
      final note = FakeVoiceNoteModel(
        voiceNoteId: 'u2',
        voiceNoteTitle: 't',
        onSave: () async {
          throw StateError('cannot save');
        },
      );

      expect(
        () => VoiceNoteRepo.updateVoiceNote(note),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Error updating voice note'))),
      );
    });
  });

  group('VoiceNoteRepo.getAllVoiceNotes', () {
    test('returns notes sorted by createdAt desc', () async {
      final n1 = FakeVoiceNoteModel(voiceNoteId: '1', voiceNoteTitle: 'a', createdAt: DateTime(2023, 1, 1));
      final n2 = FakeVoiceNoteModel(voiceNoteId: '2', voiceNoteTitle: 'b', createdAt: DateTime(2024, 1, 1));
      final n3 = FakeVoiceNoteModel(voiceNoteId: '3', voiceNoteTitle: 'c', createdAt: DateTime(2022, 1, 1));
      await VoiceNoteRepo.addVoiceNote(n1);
      await VoiceNoteRepo.addVoiceNote(n2);
      await VoiceNoteRepo.addVoiceNote(n3);

      final list = await VoiceNoteRepo.getAllVoiceNotes();
      expect(list.map((e) => (e as FakeVoiceNoteModel).voiceNoteId), ['2', '1', '3']);
    });

    test('wraps errors from box access', () async {
      final throwingHive = _ThrowingHive();
      hive.Hive = throwingHive;
      hive_flutter.Hive = throwingHive as hive_flutter.HiveInterface;

      expect(
        () => VoiceNoteRepo.getAllVoiceNotes(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Error getting all voice notes'))),
      );
    });
  });

  group('VoiceNoteRepo.getVoiceNoteById', () {
    test('returns null when not found', () async {
      final res = await VoiceNoteRepo.getVoiceNoteById('missing');
      expect(res, isNull);
    });

    test('returns stored note when found', () async {
      final note = FakeVoiceNoteModel(voiceNoteId: 'x1', voiceNoteTitle: 't');
      await VoiceNoteRepo.addVoiceNote(note);
      final found = await VoiceNoteRepo.getVoiceNoteById('x1');
      expect(found, isNotNull);
      expect((found as FakeVoiceNoteModel).voiceNoteTitle, 't');
    });

    test('wraps errors on failure', () async {
      final throwingHive = _ThrowingHive();
      hive.Hive = throwingHive;
      hive_flutter.Hive = throwingHive as hive_flutter.HiveInterface;

      expect(
        () => VoiceNoteRepo.getVoiceNoteById('any'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Error getting voice note by ID'))),
      );
    });
  });

  group('VoiceNoteRepo.deleteVoiceNote', () {
    test('deletes by key when key exists', () async {
      final n = FakeVoiceNoteModel(voiceNoteId: 'del', voiceNoteTitle: 't');
      await VoiceNoteRepo.addVoiceNote(n);
      expect(box.get('del'), isNotNull);

      await VoiceNoteRepo.deleteVoiceNote(n);
      expect(box.get('del'), isNull);
    });

    test('deletes by iterating keys when stored under different key', () async {
      // Store under non-ID key to force scan path
      await box.put(999, FakeVoiceNoteModel(voiceNoteId: 'scan', voiceNoteTitle: 't'));
      expect(await VoiceNoteRepo.getVoiceNoteById('scan'), isNull); // get by id uses box.get(id)

      await VoiceNoteRepo.deleteVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'scan', voiceNoteTitle: 'x'));
      // ensure removed
      expect(box.values.whereType<FakeVoiceNoteModel>().any((e) => e.voiceNoteId == 'scan'), isFalse);
    });

    test('throws when note not found', () async {
      expect(
        () => VoiceNoteRepo.deleteVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'nope', voiceNoteTitle: 'x')),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Voice note not found in database'))),
      );
    });

    test('throws if delete did not remove item', () async {
      final stubborn = _StubbornDeleteBox<VoiceNoteModel>('voice_notes');
      (hive.Hive as FakeHive).registerBox<VoiceNoteModel>('voice_notes', stubborn);
      hive_flutter.Hive = hive.Hive as hive_flutter.HiveInterface;

      // Preload an item under exact key
      await stubborn.put('k', FakeVoiceNoteModel(voiceNoteId: 'k', voiceNoteTitle: 't'));

      expect(
        () => VoiceNoteRepo.deleteVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'k', voiceNoteTitle: 't')),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Failed to delete voice note'))),
      );
    });

    test('wraps errors on unexpected failure', () async {
      final throwingBox = _ThrowingBox<VoiceNoteModel>('voice_notes', deleteThrows: true);
      (hive.Hive as FakeHive).registerBox<VoiceNoteModel>('voice_notes', throwingBox);
      hive_flutter.Hive = hive.Hive as hive_flutter.HiveInterface;

      await throwingBox.put('a', FakeVoiceNoteModel(voiceNoteId: 'a', voiceNoteTitle: 't'));
      expect(
        () => VoiceNoteRepo.deleteVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'a', voiceNoteTitle: 't')),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Error deleting voice note'))),
      );
    });
  });

  group('VoiceNoteRepo.searchVoiceNotes', () {
    setUp(() async {
      // Seed several notes
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(
        voiceNoteId: '1',
        voiceNoteTitle: 'Meeting with Bob',
        description: 'Discuss Q3 plans',
        tags: ['work', 'planning'],
        createdAt: DateTime(2024, 2, 1),
      ));
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(
        voiceNoteId: '2',
        voiceNoteTitle: 'Grocery list',
        description: 'Buy eggs and milk',
        tags: ['personal', 'home'],
        createdAt: DateTime(2024, 3, 1),
      ));
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(
        voiceNoteId: '3',
        voiceNoteTitle: 'Workout Routine',
        description: null,
        tags: ['health'],
        createdAt: DateTime(2024, 1, 15),
      ));
    });

    test('empty query returns all sorted by createdAt desc', () async {
      final result = await VoiceNoteRepo.searchVoiceNotes('');
      expect(result.length, 3);
      expect((result.first as FakeVoiceNoteModel).voiceNoteId, '2');
    });

    test('filters by title, description, or tags (case-insensitive)', () async {
      final titleMatch = await VoiceNoteRepo.searchVoiceNotes('bob');
      expect(titleMatch.map((e) => (e as FakeVoiceNoteModel).voiceNoteId), contains('1'));

      final descMatch = await VoiceNoteRepo.searchVoiceNotes('eggs');
      expect(descMatch.map((e) => (e as FakeVoiceNoteModel).voiceNoteId), contains('2'));

      final tagMatch = await VoiceNoteRepo.searchVoiceNotes('HEALTH');
      expect(tagMatch.map((e) => (e as FakeVoiceNoteModel).voiceNoteId), contains('3'));
    });

    test('wraps errors when box access fails', () async {
      final throwingHive = _ThrowingHive();
      hive.Hive = throwingHive;
      hive_flutter.Hive = throwingHive as hive_flutter.HiveInterface;

      expect(
        () => VoiceNoteRepo.searchVoiceNotes('anything'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Error searching voice notes'))),
      );
    });
  });

  group('VoiceNoteRepo.getVoiceNotesByUserId', () {
    test('returns filtered and sorted notes for userId', () async {
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'a', voiceNoteTitle: 't', userId: 'u1', createdAt: DateTime(2024, 1, 2)));
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'b', voiceNoteTitle: 't', userId: 'u1', createdAt: DateTime(2024, 1, 3)));
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'c', voiceNoteTitle: 't', userId: 'u2', createdAt: DateTime(2024, 1, 4)));

      final list = await VoiceNoteRepo.getVoiceNotesByUserId('u1');
      expect(list.map((e) => (e as FakeVoiceNoteModel).voiceNoteId), ['b', 'a']);
    });

    test('wraps errors from Hive', () async {
      final throwingHive = _ThrowingHive();
      hive.Hive = throwingHive;
      hive_flutter.Hive = throwingHive as hive_flutter.HiveInterface;

      expect(
        () => VoiceNoteRepo.getVoiceNotesByUserId('u1'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Error getting voice notes by user ID'))),
      );
    });
  });

  group('VoiceNoteRepo.getUnsyncedVoiceNotes', () {
    test('returns only unsynced notes', () async {
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(voiceNoteId: 's1', voiceNoteTitle: 't', isSynced: false));
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(voiceNoteId: 's2', voiceNoteTitle: 't', isSynced: true));

      final list = await VoiceNoteRepo.getUnsyncedVoiceNotes();
      expect(list.map((e) => (e as FakeVoiceNoteModel).voiceNoteId).toList(), ['s1']);
    });

    test('wraps errors from Hive', () async {
      final throwingHive = _ThrowingHive();
      hive.Hive = throwingHive;
      hive_flutter.Hive = throwingHive as hive_flutter.HiveInterface;

      expect(
        () => VoiceNoteRepo.getUnsyncedVoiceNotes(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Error getting unsynced voice notes'))),
      );
    });
  });

  group('VoiceNoteRepo.clearAllVoiceNotes', () {
    test('clears all notes', () async {
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'x', voiceNoteTitle: 't'));
      expect(box.values, isNotEmpty);
      await VoiceNoteRepo.clearAllVoiceNotes();
      expect(box.values, isEmpty);
    });

    test('wraps errors from clear()', () async {
      final throwingBox = _ThrowingBox<VoiceNoteModel>('voice_notes', clearThrows: true);
      (hive.Hive as FakeHive).registerBox<VoiceNoteModel>('voice_notes', throwingBox);
      hive_flutter.Hive = hive.Hive as hive_flutter.HiveInterface;

      expect(
        () => VoiceNoteRepo.clearAllVoiceNotes(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Error clearing all voice notes'))),
      );
    });
  });

  group('VoiceNoteRepo.debugShowAllVoiceNotes', () {
    test('iterates through keys without throwing', () async {
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'd1', voiceNoteTitle: 't'));
      await VoiceNoteRepo.addVoiceNote(FakeVoiceNoteModel(voiceNoteId: 'd2', voiceNoteTitle: 't'));
      await VoiceNoteRepo.debugShowAllVoiceNotes();
    });

    test('wraps errors when box access fails', () async {
      final throwingHive = _ThrowingHive();
      hive.Hive = throwingHive;
      hive_flutter.Hive = throwingHive as hive_flutter.HiveInterface;

      expect(
        () => VoiceNoteRepo.debugShowAllVoiceNotes(),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Error showing debug info'))),
      );
    });
  });
}

// ---- Specialized throwing test doubles ----
class _ThrowingHive implements hive.HiveInterface, hive_flutter.HiveInterface {
  @override
  Future<hive.Box<E>> openBox<E>(String name, {hive.Cipher? encryptionCipher, List<int>? bytes, String? path, bool crashRecovery = true}) async {
    throw StateError('openBox failed');
  }
  @override
  bool isBoxOpen(String name) => false;
  @override
  hive.Box<E> box<E>(String name) => throw StateError('box not available');
  @override
  Future<void> close() async {}
  @override
  Future<void> deleteBoxFromDisk(String name, {String? path}) async {}
  @override
  Future<void> deleteFromDisk() async {}
  @override
  Future<void> init(String path) async {}
  @override
  Future<void> initFlutter({String? subDir}) async {}
  @override
  Future<void> resetAdapters() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingBox<T> extends InMemoryBox<T> {
  final bool putThrows;
  final bool deleteThrows;
  final bool clearThrows;

  _ThrowingBox(String name, {this.putThrows = false, this.deleteThrows = false, this.clearThrows = false}) : super(name);

  @override
  Future<void> put(dynamic key, T value) async {
    if (putThrows) throw StateError('put failed');
    await super.put(key, value);
  }

  @override
  Future<void> delete(dynamic key) async {
    if (deleteThrows) throw StateError('delete failed');
    await super.delete(key);
  }

  @override
  Future<int> clear() async {
    if (clearThrows) throw StateError('clear failed');
    return super.clear();
  }
}

class _StubbornDeleteBox<T> extends InMemoryBox<T> {
  _StubbornDeleteBox(String name) : super(name);

  @override
  Future<void> delete(dynamic key) async {
    // Do nothing; simulates a failed delete that leaves the item intact.
  }
}