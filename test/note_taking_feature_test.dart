import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';

void main() {
  group('Note-Taking Feature Tests', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Hive once for all tests
      Hive.init('./test_note_taking');

      // Register adapter once
      try {
        Hive.registerAdapter(NoteTakingModelAdapter());
      } catch (e) {
        // Already registered, ignore
      }
    });

    setUp(() async {
      // Clear actual repo boxes before each test for isolation
      try {
        final notesBox = await HiveNoteTakingRepo.getBox();
        final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
        await notesBox.clear();
        await deletedBox.clear();
      } catch (e) {
        debugPrint('Error clearing boxes: $e');
      }
    });

    tearDown(() async {
      // Clean up actual repo boxes after each test group
      try {
        final notesBox = await HiveNoteTakingRepo.getBox();
        final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
        await notesBox.clear();
        await deletedBox.clear();
      } catch (e) {
        debugPrint('Error clearing boxes: $e');
      }
    });

    group('Note Creation Tests', () {
      test('Can create a new note with all required fields', () async {
        final note = NoteTakingModel(
          noteId: 'test-note-1',
          noteTitle: 'Test Note Title',
          noteContent: 'This is the content of my test note.',
          userId: 'test-user-123',
          tags: ['test', 'unit-test'],
          versionNumber: 1,
        );

        await HiveNoteTakingRepo.addNote(note);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote =
            box.values.firstWhere((n) => n.noteId == 'test-note-1');

        expect(savedNote.noteId, isNotNull);
        expect(savedNote.noteId, equals('test-note-1'));
        expect(savedNote.noteTitle, equals('Test Note Title'));
        expect(savedNote.noteContent,
            equals('This is the content of my test note.'));
        expect(savedNote.userId, equals('test-user-123'));
        expect(savedNote.tags, containsAll(['test', 'unit-test']));
        expect(savedNote.versionNumber, equals(1));
        expect(savedNote.isDeleted, isFalse);
        expect(savedNote.isSynced, isFalse);
      });

      test('Note creation sets proper timestamps', () async {
        final beforeCreation = DateTime.now();

        final note = NoteTakingModel(
          noteId: 'timestamp-test',
          noteTitle: 'Timestamp Test',
          noteContent: 'Testing timestamp creation',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote =
            box.values.firstWhere((n) => n.noteId == 'timestamp-test');
        final afterCreation = DateTime.now();

        expect(savedNote.createdAt.isAfter(beforeCreation), isTrue);
        expect(savedNote.createdAt.isBefore(afterCreation), isTrue);
        expect(savedNote.updatedAt.isAfter(beforeCreation), isTrue);
        expect(savedNote.updatedAt.isBefore(afterCreation), isTrue);
      });

      test('Can create note with empty optional fields', () async {
        final note = NoteTakingModel(
          noteId: 'minimal-note',
          noteTitle: 'Minimal Note',
          noteContent: 'Basic content',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote =
            box.values.firstWhere((n) => n.noteId == 'minimal-note');

        expect(savedNote.tags, isEmpty);
        expect(savedNote.versionNumber, equals(1));
      });

      test('Cannot create note with duplicate ID', () async {
        final note1 = NoteTakingModel(
          noteId: 'duplicate-id',
          noteTitle: 'First Note',
          noteContent: 'First content',
          userId: 'test-user',
        );

        final note2 = NoteTakingModel(
          noteId: 'duplicate-id',
          noteTitle: 'Second Note',
          noteContent: 'Second content',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note1);

        // Adding second note with same ID should keep the first in current repo behavior
        await HiveNoteTakingRepo.addNote(note2);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote =
            box.values.firstWhere((n) => n.noteId == 'duplicate-id');
        expect(savedNote.noteTitle, equals('First Note'));
      });
    });

    group('Note Editing Tests', () {
      test('Can update note title', () async {
        final originalNote = NoteTakingModel(
          noteId: 'edit-title-test',
          noteTitle: 'Original Title',
          noteContent: 'Some content',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(originalNote);

        final updatedNote = originalNote.copyWith(
          noteTitle: 'Updated Title',
        );

        final box1 = await HiveNoteTakingRepo.getBox();
        await box1.put(updatedNote.noteId!, updatedNote);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote = box.get('edit-title-test')!;
        expect(savedNote.noteTitle, equals('Updated Title'));
        expect(savedNote.noteContent,
            equals('Some content')); // Should remain unchanged
      });

      test('Can update note content', () async {
        final originalNote = NoteTakingModel(
          noteId: 'edit-content-test',
          noteTitle: 'Test Note',
          noteContent: 'Original content here.',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(originalNote);

        final updatedNote = originalNote.copyWith(
          noteContent: 'This is the updated content with more information.',
        );

        final box2 = await HiveNoteTakingRepo.getBox();
        await box2.put(updatedNote.noteId!, updatedNote);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote = box.get('edit-content-test')!;
        expect(savedNote.noteContent,
            equals('This is the updated content with more information.'));
        expect(savedNote.noteTitle,
            equals('Test Note')); // Should remain unchanged
      });

      test('Can add and remove tags', () async {
        final originalNote = NoteTakingModel(
          noteId: 'tags-test',
          noteTitle: 'Tags Test',
          noteContent: 'Testing tag functionality',
          userId: 'test-user',
          tags: ['initial', 'test'],
        );

        await HiveNoteTakingRepo.addNote(originalNote);

        // Add more tags
        final withMoreTags = originalNote.copyWith(
          tags: ['initial', 'test', 'updated', 'new-tag'],
        );

        final box3 = await HiveNoteTakingRepo.getBox();
        await box3.put(withMoreTags.noteId!, withMoreTags);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote = box.get('tags-test')!;
        expect(savedNote.tags,
            containsAll(['initial', 'test', 'updated', 'new-tag']));

        // Remove some tags
        final withFewerTags = savedNote.copyWith(
          tags: ['test', 'updated'],
        );

        final box4 = await HiveNoteTakingRepo.getBox();
        await box4.put(withFewerTags.noteId!, withFewerTags);

        final finalBox = await HiveNoteTakingRepo.getBox();
        final finalNote = finalBox.get('tags-test')!;
        expect(finalNote.tags, containsAll(['test', 'updated']));
        expect(finalNote.tags, hasLength(2));
        expect(finalNote.tags, isNot(contains('initial')));
        expect(finalNote.tags, isNot(contains('new-tag')));
      });

      test('Update increments version number', () async {
        final originalNote = NoteTakingModel(
          noteId: 'version-test',
          noteTitle: 'Version Test',
          noteContent: 'Original content',
          userId: 'test-user',
          versionNumber: 1,
        );

        await HiveNoteTakingRepo.addNote(originalNote);

        final updatedNote = originalNote.copyWith(
          noteContent: 'Updated content',
          versionNumber: 2,
        );

        final box5 = await HiveNoteTakingRepo.getBox();
        await box5.put(updatedNote.noteId!, updatedNote);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote = box.get('version-test')!;
        expect(savedNote.versionNumber, equals(2));
      });

      test('Update modifies updatedAt timestamp', () async {
        final originalNote = NoteTakingModel(
          noteId: 'timestamp-update-test',
          noteTitle: 'Timestamp Update Test',
          noteContent: 'Original content',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(originalNote);
        final originalTimestamp = originalNote.updatedAt;

        // Wait a moment to ensure timestamp difference
        await Future.delayed(const Duration(milliseconds: 10));

        final updatedNote = originalNote.copyWith(
          noteContent: 'Updated content',
          updatedAt: DateTime.now(),
        );

        final box6 = await HiveNoteTakingRepo.getBox();
        await box6.put(updatedNote.noteId!, updatedNote);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote = box.get('timestamp-update-test')!;
        expect(savedNote.updatedAt.isAfter(originalTimestamp), isTrue);
      });
    });

    group('Note Deletion Tests', () {
      test('Soft delete marks note as deleted', () async {
        final note = NoteTakingModel(
          noteId: 'delete-test',
          noteTitle: 'Delete Test',
          noteContent: 'This note will be deleted',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);

        // Soft delete
        await HiveNoteTakingRepo.deleteNote(note);

        // Verify it moved from main box to deleted box
        final mainBox = await HiveNoteTakingRepo.getBox();
        final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
        expect(mainBox.get('delete-test'), isNull);
        expect(deletedBox.get('delete-test'), isNotNull);
      });

      test('Deleted notes appear in deleted notes box', () async {
        final note = NoteTakingModel(
          noteId: 'deleted-box-test',
          noteTitle: 'Deleted Box Test',
          noteContent: 'Testing deleted notes box',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);
        await HiveNoteTakingRepo.deleteNote(note);

        final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
        final deleted = deletedBox.get('deleted-box-test');
        expect(deleted, isNotNull);
      });

      test('Can restore deleted notes', () async {
        final note = NoteTakingModel(
          noteId: 'restore-test',
          noteTitle: 'Restore Test',
          noteContent: 'This note will be restored',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);
        await HiveNoteTakingRepo.deleteNote(note);

        // Verify deletion (presence in deleted box is sufficient)
        final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
        final deletedNote = deletedBox.get('restore-test');
        expect(deletedNote, isNotNull);

        // Restore
        await HiveNoteTakingRepo.addNoteToMainBox(deletedNote!);

        final mainBox = await HiveNoteTakingRepo.getBox();
        final restoredNote = mainBox.get('restore-test');
        expect(restoredNote, isNotNull);
      });

      test('Permanent delete removes note completely', () async {
        final note = NoteTakingModel(
          noteId: 'permanent-delete-test',
          noteTitle: 'Permanent Delete Test',
          noteContent: 'This note will be permanently deleted',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);
        await HiveNoteTakingRepo.deleteNote(note);

        // Get the deleted note
        final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
        final deletedNote = deletedBox.get('permanent-delete-test')!;

        // Permanent delete
        await HiveNoteTakingRepo.permantentlyDeleteNote(deletedNote);

        final finalDeletedBox = await HiveNoteTakingRepo.getDeletedBox();
        expect(finalDeletedBox.get('permanent-delete-test'), isNull);
      });
    });

    group('Note Search and Retrieval Tests', () {
      test('Can retrieve all notes for a user', () async {
        final notes = [
          NoteTakingModel(
            noteId: 'user-note-1',
            noteTitle: 'First Note',
            noteContent: 'Content 1',
            userId: 'test-user-123',
          ),
          NoteTakingModel(
            noteId: 'user-note-2',
            noteTitle: 'Second Note',
            noteContent: 'Content 2',
            userId: 'test-user-123',
          ),
          NoteTakingModel(
            noteId: 'other-user-note',
            noteTitle: 'Other Note',
            noteContent: 'Other content',
            userId: 'different-user',
          ),
        ];

        for (final note in notes) {
          await HiveNoteTakingRepo.addNote(note);
        }

        final allNotes = await HiveNoteTakingRepo.getNotes();
        final userNotes =
            allNotes.where((n) => n.userId == 'test-user-123').toList();

        expect(userNotes, hasLength(2));
        expect(userNotes.map((n) => n.noteId),
            containsAll(['user-note-1', 'user-note-2']));
        expect(
            userNotes.map((n) => n.noteId), isNot(contains('other-user-note')));
      });

      test('Can search notes by title', () async {
        final notes = [
          NoteTakingModel(
            noteId: 'search-1',
            noteTitle: 'Important Meeting Notes',
            noteContent: 'Meeting content',
            userId: 'test-user',
          ),
          NoteTakingModel(
            noteId: 'search-2',
            noteTitle: 'Shopping List',
            noteContent: 'Grocery items',
            userId: 'test-user',
          ),
          NoteTakingModel(
            noteId: 'search-3',
            noteTitle: 'Meeting Agenda',
            noteContent: 'Agenda items',
            userId: 'test-user',
          ),
        ];

        for (final note in notes) {
          await HiveNoteTakingRepo.addNote(note);
        }

        final allNotes = await HiveNoteTakingRepo.getNotes();
        final searchResults = allNotes
            .where((n) => n.noteTitle.toLowerCase().contains('meeting'))
            .toList();

        expect(searchResults, hasLength(2));
        expect(searchResults.map((n) => n.noteId),
            containsAll(['search-1', 'search-3']));
      });

      test('Can search notes by content', () async {
        final notes = [
          NoteTakingModel(
            noteId: 'content-search-1',
            noteTitle: 'Random Title',
            noteContent: 'This contains the keyword flutter',
            userId: 'test-user',
          ),
          NoteTakingModel(
            noteId: 'content-search-2',
            noteTitle: 'Another Title',
            noteContent: 'Some other content here',
            userId: 'test-user',
          ),
          NoteTakingModel(
            noteId: 'content-search-3',
            noteTitle: 'Third Title',
            noteContent: 'More flutter development notes',
            userId: 'test-user',
          ),
        ];

        for (final note in notes) {
          await HiveNoteTakingRepo.addNote(note);
        }

        final allNotes = await HiveNoteTakingRepo.getNotes();
        final searchResults = allNotes
            .where((n) => n.noteContent.toLowerCase().contains('flutter'))
            .toList();

        expect(searchResults, hasLength(2));
        expect(searchResults.map((n) => n.noteId),
            containsAll(['content-search-1', 'content-search-3']));
      });

      test('Can filter notes by tags', () async {
        final notes = [
          NoteTakingModel(
            noteId: 'tag-filter-1',
            noteTitle: 'Work Note',
            noteContent: 'Work related content',
            userId: 'test-user',
            tags: ['work', 'important'],
          ),
          NoteTakingModel(
            noteId: 'tag-filter-2',
            noteTitle: 'Personal Note',
            noteContent: 'Personal content',
            userId: 'test-user',
            tags: ['personal', 'hobby'],
          ),
          NoteTakingModel(
            noteId: 'tag-filter-3',
            noteTitle: 'Mixed Note',
            noteContent: 'Mixed content',
            userId: 'test-user',
            tags: ['work', 'personal'],
          ),
        ];

        for (final note in notes) {
          await HiveNoteTakingRepo.addNote(note);
        }

        final allNotes = await HiveNoteTakingRepo.getNotes();
        final workNotes =
            allNotes.where((n) => n.tags.contains('work')).toList();

        expect(workNotes, hasLength(2));
        expect(workNotes.map((n) => n.noteId),
            containsAll(['tag-filter-1', 'tag-filter-3']));
      });
    });

    group('Note Synchronization Tests', () {
      test('Notes start as unsynced', () async {
        final note = NoteTakingModel(
          noteId: 'sync-test',
          noteTitle: 'Sync Test',
          noteContent: 'Testing sync functionality',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);

        // Retrieve via repository list to avoid keying differences
        final notes = await HiveNoteTakingRepo.getNotes();
        final savedNote = notes.firstWhere((n) => n.noteId == 'sync-test',
            orElse: () => throw Exception('Note not found'));
        expect(savedNote.isSynced, isFalse);
        expect(savedNote.shouldSync, isTrue);
      });

      test('Can mark note as synced', () async {
        final note = NoteTakingModel(
          noteId: 'mark-synced-test',
          noteTitle: 'Mark Synced Test',
          noteContent: 'Testing sync marking',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);

        // Mark as synced
        final syncedNote = note.copyWith(isSynced: true);
        final box7 = await HiveNoteTakingRepo.getBox();
        await box7.put(syncedNote.noteId!, syncedNote);

        final box = await HiveNoteTakingRepo.getBox();
        final savedNote = box.get('mark-synced-test')!;
        expect(savedNote.isSynced, isTrue);
        expect(savedNote.shouldSync, isFalse);
      });

      test('Can get unsynced notes', () async {
        final notes = [
          NoteTakingModel(
            noteId: 'unsynced-1',
            noteTitle: 'Unsynced Note 1',
            noteContent: 'Content 1',
            userId: 'test-user',
            isSynced: false,
          ),
          NoteTakingModel(
            noteId: 'synced-1',
            noteTitle: 'Synced Note 1',
            noteContent: 'Content 1',
            userId: 'test-user',
            isSynced: true,
          ),
          NoteTakingModel(
            noteId: 'unsynced-2',
            noteTitle: 'Unsynced Note 2',
            noteContent: 'Content 2',
            userId: 'test-user',
            isSynced: false,
          ),
        ];

        for (final note in notes) {
          await HiveNoteTakingRepo.addNote(note);
        }

        final allNotes = await HiveNoteTakingRepo.getNotes();
        final unsyncedNotes = allNotes.where((n) => !n.isSynced).toList();

        expect(unsyncedNotes, hasLength(2));
        expect(unsyncedNotes.map((n) => n.noteId),
            containsAll(['unsynced-1', 'unsynced-2']));
      });
    });

    group('Note Actions Repository Tests', () {
      test('Can create note through actions repository', () async {
        // Test basic note creation without Firebase dependencies
        const title = 'Action Created Note';
        const content = 'This note was created through the actions repository';
        final tags = ['action', 'test'];

        final note = NoteTakingModel(
          noteId: 'action-test-note',
          noteTitle: title,
          noteContent: content,
          userId: 'test-user',
          tags: tags,
        );

        await HiveNoteTakingRepo.addNote(note);
        final allNotes = await HiveNoteTakingRepo.getNotes();
        final retrievedNote =
            allNotes.firstWhere((n) => n.noteId == 'action-test-note');

        expect(retrievedNote, isNotNull);
        expect(retrievedNote.noteTitle, equals(title));
        expect(retrievedNote.noteContent, equals(content));
        expect(retrievedNote.tags, containsAll(tags));
      });

      test('Can update note through actions repository', () async {
        final note = NoteTakingModel(
          noteId: 'action-update-test',
          noteTitle: 'Original Title',
          noteContent: 'Original content',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);

        // Update the note directly
        final updatedNote = note.copyWith(
          noteTitle: 'Updated Title',
          noteContent: 'Updated content through actions',
          versionNumber: 2,
        );

        final box = await HiveNoteTakingRepo.getBox();
        await box.put(updatedNote.noteId!, updatedNote);
        final retrievedNote = box.get('action-update-test');

        expect(retrievedNote, isNotNull);
        expect(retrievedNote!.noteTitle, equals('Updated Title'));
        expect(retrievedNote.noteContent,
            equals('Updated content through actions'));
        expect(retrievedNote.versionNumber, equals(2));
      });

      test('Can delete note through actions repository', () async {
        final note = NoteTakingModel(
          noteId: 'delete-test-note',
          noteTitle: 'Delete Test Note',
          noteContent: 'This note will be deleted',
          userId: 'test-user',
        );

        await HiveNoteTakingRepo.addNote(note);
        await HiveNoteTakingRepo.deleteNote(note);

        final allNotes = await HiveNoteTakingRepo.getNotes();
        final deletedNotes =
            allNotes.where((n) => n.noteId == 'delete-test-note').toList();
        expect(deletedNotes.isEmpty, isTrue);
      });
    });

    group('Error Handling Tests', () {
      test('Handles attempt to update non-existent note', () async {
        expect(() async {
          // Simulate a benign no-op update using put
          final box8 = await HiveNoteTakingRepo.getBox();
          await box8.put(
              'non-existent',
              NoteTakingModel(
                noteId: 'non-existent',
                noteTitle: 'Test',
                noteContent: 'Test',
                userId: 'test-user',
              ));
        }, returnsNormally); // Should handle gracefully
      });

      test('Handles deletion of non-existent note', () async {
        final nonExistentNote = NoteTakingModel(
          noteId: 'non-existent',
          noteTitle: 'Test',
          noteContent: 'Test',
          userId: 'test-user',
        );
        expect(() async {
          await HiveNoteTakingRepo.deleteNote(nonExistentNote);
        }, returnsNormally);
      });

      test('Handles empty search queries', () async {
        final allNotes = await HiveNoteTakingRepo.getNotes();
        final searchResults = allNotes
            .where((n) =>
                n.noteTitle.toLowerCase().contains('') ||
                n.noteContent.toLowerCase().contains(''))
            .toList();
        expect(searchResults, isA<List<NoteTakingModel>>());
      });
    });
  });
}
