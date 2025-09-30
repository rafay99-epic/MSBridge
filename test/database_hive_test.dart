import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/database/note_taking/note_version.dart';
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';

void main() {
  group('Database and Hive Persistence Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Hive for testing
      Hive.init('./test_hive_db');

      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(NoteTakingModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(NoteVersionAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ChatHistoryAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(ChatHistoryMessageAdapter());
      }
      if (!Hive.isAdapterRegistered(5)) {
        Hive.registerAdapter(NoteTemplateAdapter());
      }
      if (!Hive.isAdapterRegistered(6)) {
        Hive.registerAdapter(VoiceNoteModelAdapter());
      }
    });

    tearDownAll(() async {
      // Clean up all test boxes
      final testBoxes = [
        'test_notes_persistence',
        'test_note_versions',
        'test_chat_history',
        'test_templates',
        'test_voice_notes',
        'test_deleted_notes',
        'test_basic_box',
        'test_box1',
        'test_box2',
        'test_box3',
        'test_integrity',
        'test_large_content',
        'test_concurrent',
        'test_performance',
      ];

      for (final boxName in testBoxes) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
            await box.close();
          }
        } catch (e) {
          // Ignore cleanup errors in tests
        }
      }
    });

    group('Note Taking Model Persistence', () {
      setUp(() async {
        // Clear the box before each test
        if (Hive.isBoxOpen('test_notes_persistence')) {
          final box = Hive.box<NoteTakingModel>('test_notes_persistence');
          await box.clear();
        }
      });

      test('NoteTakingModel can be saved and retrieved from Hive', () async {
        final box =
            await Hive.openBox<NoteTakingModel>('test_notes_persistence');

        final testNote = NoteTakingModel(
          noteId: 'test-note-1',
          noteTitle: 'Test Note',
          noteContent: 'This is a test note content',
          userId: 'test-user-123',
          tags: ['test', 'unit-test'],
          versionNumber: 1,
        );

        // Save note
        await box.put(testNote.noteId!, testNote);

        // Retrieve note
        final retrievedNote = box.get(testNote.noteId!);

        expect(retrievedNote, isNotNull);
        expect(retrievedNote!.noteId, equals(testNote.noteId));
        expect(retrievedNote.noteTitle, equals(testNote.noteTitle));
        expect(retrievedNote.noteContent, equals(testNote.noteContent));
        expect(retrievedNote.userId, equals(testNote.userId));
        expect(retrievedNote.tags, containsAll(testNote.tags));
        expect(retrievedNote.versionNumber, equals(testNote.versionNumber));
      });

      test('Multiple notes can be stored and queried', () async {
        final box =
            await Hive.openBox<NoteTakingModel>('test_notes_persistence');

        final notes = List.generate(
            5,
            (index) => NoteTakingModel(
                  noteId: 'test-note-$index',
                  noteTitle: 'Test Note $index',
                  noteContent: 'Content for test note $index',
                  userId: 'test-user-123',
                  tags: ['test', 'batch-$index'],
                  versionNumber: 1,
                ));

        // Save all notes
        for (final note in notes) {
          await box.put(note.noteId!, note);
        }

        expect(box.length, equals(5));

        // Query specific note
        final specificNote = box.get('test-note-2');
        expect(specificNote, isNotNull);
        expect(specificNote!.noteTitle, equals('Test Note 2'));

        // Get all notes
        final allNotes = box.values.toList();
        expect(allNotes.length, equals(5));
      });

      test('Note deletion and recovery works correctly', () async {
        final box =
            await Hive.openBox<NoteTakingModel>('test_notes_persistence');

        final testNote = NoteTakingModel(
          noteId: 'deletion-test-note',
          noteTitle: 'Test Deletion',
          noteContent: 'This note will be deleted',
          userId: 'test-user-123',
        );

        await box.put(testNote.noteId!, testNote);
        expect(box.containsKey(testNote.noteId!), isTrue);

        // Mark as deleted (soft delete)
        testNote.markAsDeleted('device-123', 'test-user-123');
        await box.put(testNote.noteId!, testNote); // Save changes to box

        final deletedNote = box.get(testNote.noteId!);
        expect(deletedNote!.isDeleted, isTrue);
        expect(deletedNote.deletedAt, isNotNull);
        expect(deletedNote.deletedBy, equals('test-user-123'));

        // Restore note
        deletedNote.restore();
        await box.put(deletedNote.noteId!, deletedNote);

        final restoredNote = box.get(testNote.noteId!);
        expect(restoredNote!.isDeleted, isFalse);
        expect(restoredNote.deletedAt, isNull);
        expect(restoredNote.deletedBy, isNull);
      });

      test('Note synchronization flags work correctly', () async {
        final box =
            await Hive.openBox<NoteTakingModel>('test_notes_persistence');

        final testNote = NoteTakingModel(
          noteId: 'sync-test-note',
          noteTitle: 'Test Sync',
          noteContent: 'This note tests sync flags',
          userId: 'test-user-123',
        );

        await box.put(testNote.noteId!, testNote);

        // Initially should need sync
        expect(testNote.shouldSync, isTrue);
        expect(testNote.isSynced, isFalse);

        // Mark as synced
        testNote.isSynced = true;
        await box.put(testNote.noteId!, testNote);

        final syncedNote = box.get(testNote.noteId!);
        expect(syncedNote!.shouldSync, isFalse);
        expect(syncedNote.isSynced, isTrue);
      });

      test('Note version management works', () async {
        final testNote = NoteTakingModel(
          noteId: 'version-test-note',
          noteTitle: 'Version Test',
          noteContent: 'Original content',
          userId: 'test-user-123',
          versionNumber: 1,
        );

        expect(testNote.versionNumber, equals(1));

        // Create updated version
        final updatedNote = testNote.copyWith(
          noteContent: 'Updated content',
          versionNumber: 2,
        );

        expect(updatedNote.versionNumber, equals(2));
        expect(updatedNote.noteContent, equals('Updated content'));
        expect(updatedNote.noteTitle,
            equals('Version Test')); // Should remain same
      });
    });

    group('Chat History Persistence', () {
      setUp(() async {
        if (Hive.isBoxOpen('test_chat_history')) {
          final box = Hive.box<ChatHistory>('test_chat_history');
          await box.clear();
        }
      });

      test('ChatHistory can be saved and retrieved', () async {
        final box = await Hive.openBox<ChatHistory>('test_chat_history');

        final chatHistory = ChatHistory(
          id: 'chat-1',
          title: 'Test Chat',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          includePersonal: true,
          includeMsNotes: true,
          modelName: 'test-model',
          messages: [
            ChatHistoryMessage(
              text: 'Hello, this is a test message',
              fromUser: true,
              timestamp: DateTime.now(),
              isError: false,
            ),
          ],
        );

        await box.put(chatHistory.id, chatHistory);

        final retrieved = box.get(chatHistory.id);
        expect(retrieved, isNotNull);
        expect(retrieved!.id, equals(chatHistory.id));
        expect(retrieved.title, equals(chatHistory.title));
        expect(retrieved.messages.length, equals(1));
        expect(retrieved.messages.first.text,
            equals('Hello, this is a test message'));
      });
    });

    group('Template Persistence', () {
      setUp(() async {
        if (Hive.isBoxOpen('test_templates')) {
          final box = Hive.box<NoteTemplate>('test_templates');
          await box.clear();
        }
      });

      test('NoteTemplate can be saved and retrieved', () async {
        final box = await Hive.openBox<NoteTemplate>('test_templates');

        final template = NoteTemplate(
          templateId: 'template-1',
          title: 'Meeting Notes Template',
          contentJson:
              '{"ops":[{"insert":"# Meeting Notes\\n\\n## Attendees\\n\\n## Agenda\\n\\n## Action Items\\n"}]}',
          tags: ['work'],
          userId: 'test-user',
          createdAt: DateTime.now(),
          isBuiltIn: false,
        );

        await box.put(template.templateId, template);

        final retrieved = box.get(template.templateId);
        expect(retrieved, isNotNull);
        expect(retrieved!.templateId, equals(template.templateId));
        expect(retrieved.title, equals(template.title));
        expect(retrieved.contentJson, contains('Meeting Notes'));
        expect(retrieved.tags, contains('work'));
      });
    });

    group('Voice Note Persistence', () {
      setUp(() async {
        if (Hive.isBoxOpen('test_voice_notes')) {
          final box = Hive.box<VoiceNoteModel>('test_voice_notes');
          await box.clear();
        }
      });

      test('VoiceNoteModel can be saved and retrieved', () async {
        final box = await Hive.openBox<VoiceNoteModel>('test_voice_notes');

        final voiceNote = VoiceNoteModel(
          voiceNoteId: 'voice-1',
          voiceNoteTitle: 'Test Recording',
          audioFilePath: '/test/path/recording.m4a',
          durationInSeconds: 120, // 2 minutes
          fileSizeInBytes: 1024000, // 1MB
          createdAt: DateTime.now(),
          userId: 'test-user-123',
          isSynced: false,
          isDeleted: false,
          tags: ['test'],
        );

        await box.put(voiceNote.voiceNoteId!, voiceNote);

        final retrieved = box.get(voiceNote.voiceNoteId!);
        expect(retrieved, isNotNull);
        expect(retrieved!.voiceNoteId, equals(voiceNote.voiceNoteId));
        expect(retrieved.voiceNoteTitle, equals(voiceNote.voiceNoteTitle));
        expect(retrieved.audioFilePath, equals(voiceNote.audioFilePath));
        expect(retrieved.durationInSeconds, equals(120));
        expect(retrieved.userId, equals(voiceNote.userId));
      });
    });

    group('Database Migration and Safety', () {
      test('Basic Hive box operations work correctly', () async {
        // Test basic box operations without external dependencies
        final box = await Hive.openBox<String>('test_basic_box');

        await box.put('key1', 'value1');
        await box.put('key2', 'value2');

        expect(box.get('key1'), equals('value1'));
        expect(box.get('key2'), equals('value2'));
        expect(box.length, equals(2));

        await box.clear();
        expect(box.length, equals(0));
      });

      test('Multiple box operations work correctly', () async {
        final boxNames = ['box1', 'box2', 'box3'];
        final boxes = <String, Box>{};

        for (final name in boxNames) {
          boxes[name] = await Hive.openBox('test_$name');
        }

        expect(boxes.length, equals(3));

        for (final box in boxes.values) {
          expect(box.isOpen, isTrue);
        }
      });
    });

    group('Data Integrity and Validation', () {
      test('Note data integrity is maintained across operations', () async {
        final box = await Hive.openBox<NoteTakingModel>('test_integrity');

        final originalNote = NoteTakingModel(
          noteId: 'integrity-test',
          noteTitle: 'Integrity Test',
          noteContent: 'Original content with special chars: àáâãäå',
          userId: 'user@example.com',
          tags: ['important', 'test', 'unicode'],
          versionNumber: 1,
        );

        await box.put(originalNote.noteId!, originalNote);

        // Retrieve and verify all fields
        final retrieved = box.get(originalNote.noteId!)!;

        expect(retrieved.noteId, equals(originalNote.noteId));
        expect(retrieved.noteTitle, equals(originalNote.noteTitle));
        expect(retrieved.noteContent, equals(originalNote.noteContent));
        expect(retrieved.userId, equals(originalNote.userId));
        expect(retrieved.tags, equals(originalNote.tags));
        expect(retrieved.versionNumber, equals(originalNote.versionNumber));
        expect(retrieved.createdAt.millisecondsSinceEpoch,
            closeTo(originalNote.createdAt.millisecondsSinceEpoch, 1000));
      });

      test('Large content handling', () async {
        final box = await Hive.openBox<NoteTakingModel>('test_large_content');

        final largeContent = 'A' * 10000; // 10KB of content

        final largeNote = NoteTakingModel(
          noteId: 'large-note',
          noteTitle: 'Large Content Test',
          noteContent: largeContent,
          userId: 'test-user',
        );

        await box.put(largeNote.noteId!, largeNote);

        final retrieved = box.get(largeNote.noteId!)!;
        expect(retrieved.noteContent.length, equals(10000));
        expect(retrieved.noteContent, equals(largeContent));
      });

      test('Concurrent access handling', () async {
        final box = await Hive.openBox<NoteTakingModel>('test_concurrent');

        final futures = List.generate(10, (index) async {
          final note = NoteTakingModel(
            noteId: 'concurrent-note-$index',
            noteTitle: 'Concurrent Test $index',
            noteContent: 'Content $index',
            userId: 'test-user',
          );

          await box.put(note.noteId!, note);
          return note;
        });

        await Future.wait(futures);

        expect(box.length, equals(10));

        for (int i = 0; i < 10; i++) {
          final note = box.get('concurrent-note-$i');
          expect(note, isNotNull);
          expect(note!.noteTitle, equals('Concurrent Test $i'));
        }
      });
    });

    group('Performance Tests', () {
      test('Bulk operations performance', () async {
        final box = await Hive.openBox<NoteTakingModel>('test_performance');
        final stopwatch = Stopwatch()..start();

        // Insert 1000 notes
        for (int i = 0; i < 1000; i++) {
          final note = NoteTakingModel(
            noteId: 'perf-note-$i',
            noteTitle: 'Performance Test $i',
            noteContent: 'Content for performance test $i',
            userId: 'perf-user',
          );

          await box.put(note.noteId!, note);
        }

        stopwatch.stop();
        final insertTime = stopwatch.elapsedMilliseconds;

        expect(box.length, equals(1000));
        expect(insertTime,
            lessThan(5000)); // Should complete in less than 5 seconds

        // Test query performance
        stopwatch.reset();
        stopwatch.start();

        for (int i = 0; i < 100; i++) {
          final note = box.get('perf-note-$i');
          expect(note, isNotNull);
        }

        stopwatch.stop();
        final queryTime = stopwatch.elapsedMilliseconds;

        expect(
            queryTime, lessThan(1000)); // Should complete in less than 1 second
      });
    });
  });
}
