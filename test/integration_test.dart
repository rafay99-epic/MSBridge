// Flutter imports:
import 'package:flutter/services.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Project imports:
import 'package:msbridge/core/database/chat_history/chat_history.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/database/templates/note_template.dart';
import 'package:msbridge/core/database/voice_notes/voice_note_model.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';

void main() {
  group('Integration Tests - Core Functionality', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Mock platform channels
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (methodCall) async {
          switch (methodCall.method) {
            case 'getAll':
              return <String, dynamic>{
                'flutter.appTheme': 'dark',
                'flutter.dynamicColors': false,
              };
            case 'setString':
            case 'setBool':
            case 'remove':
              return true;
            default:
              return null;
          }
        },
      );

      // Mock FlutterBugfender to avoid MissingPluginException / hangs
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter_bugfender'),
        (_) async => null,
      );

      // Mock flutter_local_notifications
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (_) async => true,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(
            'dexterous.com/flutter/local_notifications_schedule'),
        (_) async => true,
      );

      // Mock url_launcher
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/url_launcher'),
        (_) async => true,
      );

      // Mock path_provider (return a temp directory)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (_) async => '/tmp/msbridge_test',
      );

      // Initialize Hive
      Hive.init('./test_integration');

      // Register all adapters
      if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(MSNoteAdapter());
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(NoteTakingModelAdapter());
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
      // Clean up boxes
      try {
        final boxNames = [
          'notes',
          'deleted_notes',
          'integration_templates',
          'integration_chat_history',
          'integration_voice_notes'
        ];
        for (final boxName in boxNames) {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
            await box.close();
            // Note: deleteFromDisk() calls FlutterBugfender which isn't available in tests
            // await box.deleteFromDisk();
          }
        }
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    group('Note Taking Core Workflow', () {
      setUp(() async {
        // Clear boxes before each test
        try {
          final notesBox = await HiveNoteTakingRepo.getBox();
          final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
          await notesBox.clear();
          await deletedBox.clear();

          // Also clear any other boxes that might be open
          final boxNames = [
            'integration_templates',
            'integration_chat_history',
            'integration_voice_notes'
          ];
          for (final boxName in boxNames) {
            if (Hive.isBoxOpen(boxName)) {
              final box = Hive.box(boxName);
              await box.clear();
            }
          }
        } catch (e) {
          // Ignore if boxes don't exist yet
        }
      });

      test('User can create and manage notes', () async {
        // Clear boxes before this specific test
        final notesBox = await HiveNoteTakingRepo.getBox();
        final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
        await notesBox.clear();
        await deletedBox.clear();

        // Step 1: Create a note using static methods
        final note = NoteTakingModel(
          noteId: 'test-note-1',
          noteTitle: 'Test Note',
          noteContent: 'This is a test note content',
          userId: 'test-user',
          tags: ['test', 'integration'],
        );

        // Use the box directly to add the note (consistent with update)
        await notesBox.put(note.noteId!, note);

        // Step 2: Retrieve all notes
        final allNotes = await HiveNoteTakingRepo.getNotes();
        expect(allNotes.length, equals(1));
        expect(allNotes.first.noteTitle, equals('Test Note'));
        expect(allNotes.first.tags, containsAll(['test', 'integration']));

        // Step 3: Update the note
        final retrievedNote = await HiveNoteTakingRepo.getNotes();
        final noteToUpdate = retrievedNote.first;
        final updatedNote = noteToUpdate.copyWith(
          noteContent: 'Updated content',
          versionNumber: 2,
        );

        // Use the box directly to update the note
        await notesBox.put(updatedNote.noteId!, updatedNote);

        // Step 4: Verify update
        final updatedNotes = await HiveNoteTakingRepo.getNotes();
        expect(updatedNotes.length, equals(1));
        expect(updatedNotes.first.noteContent, equals('Updated content'));
        expect(updatedNotes.first.versionNumber, equals(2));

        // Step 5: Delete the note
        await HiveNoteTakingRepo.deleteNote(updatedNote);

        // Step 6: Verify deletion
        final notesAfterDeletion = await HiveNoteTakingRepo.getNotes();
        expect(notesAfterDeletion.length, equals(0));
      });

      test('User can work with templates', () async {
        // Step 1: Create a template
        final template = NoteTemplate(
          templateId: 'test-template',
          title: 'Test Template',
          contentJson:
              '{"ops":[{"insert":"# Test Template\\n\\n## Content\\n"}]}',
          tags: ['template', 'test'],
          userId: 'test-user',
          createdAt: DateTime.now(),
        );

        final templatesBox =
            await Hive.openBox<NoteTemplate>('integration_templates');
        await templatesBox.put(template.templateId, template);

        // Step 2: Retrieve template
        final retrievedTemplate = templatesBox.get(template.templateId);
        expect(retrievedTemplate, isNotNull);
        expect(retrievedTemplate!.title, equals('Test Template'));
        expect(retrievedTemplate.tags, contains('template'));

        // Step 3: Create note from template
        final noteFromTemplate = NoteTakingModel(
          noteId: 'template-note',
          noteTitle: 'Note from Template',
          noteContent: 'Content based on template',
          userId: 'test-user',
          tags: ['template-based'],
        );

        await HiveNoteTakingRepo.addNote(noteFromTemplate);

        // Step 4: Verify both template and note exist
        final templates = templatesBox.values.toList();
        final notes = await HiveNoteTakingRepo.getNotes();

        expect(templates.length, equals(1));
        expect(notes.length, equals(1));
        expect(notes.first.noteTitle, equals('Note from Template'));
      });

      test('User can manage chat history', () async {
        // Step 1: Create chat history
        final chatHistory = ChatHistory(
          id: 'test-chat',
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
            ChatHistoryMessage(
              text: 'This is a response',
              fromUser: false,
              timestamp: DateTime.now(),
              isError: false,
            ),
          ],
        );

        final chatBox =
            await Hive.openBox<ChatHistory>('integration_chat_history');
        await chatBox.put(chatHistory.id, chatHistory);

        // Step 2: Retrieve chat history
        final retrievedChat = chatBox.get(chatHistory.id);
        expect(retrievedChat, isNotNull);
        expect(retrievedChat!.title, equals('Test Chat'));
        expect(retrievedChat.messages.length, equals(2));
        expect(retrievedChat.messages.first.text,
            equals('Hello, this is a test message'));
        expect(retrievedChat.messages.last.text, equals('This is a response'));

        // Step 3: Create note based on chat
        final noteFromChat = NoteTakingModel(
          noteId: 'chat-note',
          noteTitle: 'Note from Chat',
          noteContent: 'Content based on chat conversation',
          userId: 'test-user',
          tags: ['chat-based'],
        );

        await HiveNoteTakingRepo.addNote(noteFromChat);

        // Step 4: Verify both chat and note exist
        final chats = chatBox.values.toList();
        final notes = await HiveNoteTakingRepo.getNotes();

        expect(chats.length, equals(1));
        expect(notes.length, equals(1));
        expect(notes.first.noteTitle, equals('Note from Chat'));
      });
    });

    group('Data Persistence Tests', () {
      setUp(() async {
        // Clear boxes before each test
        try {
          final notesBox = await HiveNoteTakingRepo.getBox();
          final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
          await notesBox.clear();
          await deletedBox.clear();

          // Also clear any other boxes that might be open
          final boxNames = [
            'integration_templates',
            'integration_chat_history',
            'integration_voice_notes'
          ];
          for (final boxName in boxNames) {
            if (Hive.isBoxOpen(boxName)) {
              final box = Hive.box(boxName);
              await box.clear();
            }
          }
        } catch (e) {
          // Ignore if boxes don't exist yet
        }
      });

      test('Data persists correctly across operations', () async {
        // Step 1: Create multiple notes
        final notes = List.generate(
            5,
            (index) => NoteTakingModel(
                  noteId: 'persistence-note-$index',
                  noteTitle: 'Persistence Test $index',
                  noteContent: 'Content for persistence test $index',
                  userId: 'test-user',
                  tags: ['persistence', 'test$index'],
                ));

        for (final note in notes) {
          await HiveNoteTakingRepo.addNote(note);
        }

        // Step 2: Verify all notes are stored
        final allNotes = await HiveNoteTakingRepo.getNotes();
        expect(allNotes.length, equals(5));

        // Step 3: Test sync flags
        for (final note in allNotes) {
          expect(note.isSynced, isFalse);
          expect(note.shouldSync, isTrue);
        }

        // Step 4: Mark one note as synced
        final noteToSync = allNotes.first;
        final syncedNote = noteToSync.copyWith(isSynced: true);

        // Use the box directly to update the note
        final notesBox = await HiveNoteTakingRepo.getBox();
        await notesBox.put(syncedNote.noteId!, syncedNote);

        // Step 5: Verify sync status
        final updatedNotes = await HiveNoteTakingRepo.getNotes();
        final syncedNotes = updatedNotes.where((n) => n.isSynced).toList();
        expect(syncedNotes.length, equals(1));
        expect(syncedNotes.first.noteId, equals('persistence-note-0'));
      });

      test('Handles edge cases gracefully', () async {
        // Step 1: Test with very long content
        final longContent = 'A' * 10000;
        final longNote = NoteTakingModel(
          noteId: 'long-note',
          noteTitle: 'Long Content Test',
          noteContent: longContent,
          userId: 'test-user',
          tags: List.generate(50, (i) => 'tag$i'),
        );

        expect(() async {
          await HiveNoteTakingRepo.addNote(longNote);
        }, returnsNormally);

        // Step 2: Test with special characters
        final specialNote = NoteTakingModel(
          noteId: 'special-note',
          noteTitle: 'Spéciål Çhàracters & Émojis 🚀',
          noteContent: 'Content with émojis 😊 and spéciål chars: ñáéíóú',
          userId: 'test-user',
          tags: ['special', 'unicode'],
        );

        expect(() async {
          await HiveNoteTakingRepo.addNote(specialNote);
        }, returnsNormally);

        // Step 3: Verify both notes were stored
        final allNotes = await HiveNoteTakingRepo.getNotes();
        expect(allNotes.length, equals(2));

        final longNoteRetrieved =
            allNotes.firstWhere((n) => n.noteId == 'long-note');
        expect(longNoteRetrieved.noteContent.length, equals(10000));

        final specialNoteRetrieved =
            allNotes.firstWhere((n) => n.noteId == 'special-note');
        expect(specialNoteRetrieved.noteTitle, contains('Émojis'));
        expect(specialNoteRetrieved.noteContent, contains('émojis'));
      });
    });

    group('Performance Tests', () {
      setUp(() async {
        // Clear boxes before each test
        try {
          final notesBox = await HiveNoteTakingRepo.getBox();
          final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
          await notesBox.clear();
          await deletedBox.clear();

          // Also clear any other boxes that might be open
          final boxNames = [
            'integration_templates',
            'integration_chat_history',
            'integration_voice_notes'
          ];
          for (final boxName in boxNames) {
            if (Hive.isBoxOpen(boxName)) {
              final box = Hive.box(boxName);
              await box.clear();
            }
          }
        } catch (e) {
          // Ignore if boxes don't exist yet
        }
      });

      test('Handles bulk operations efficiently', () async {
        final stopwatch = Stopwatch()..start();

        // Step 1: Create 50 notes
        for (int i = 0; i < 50; i++) {
          final note = NoteTakingModel(
            noteId: 'perf-note-$i',
            noteTitle: 'Performance Test $i',
            noteContent: 'Content for performance test $i',
            userId: 'test-user',
            tags: ['performance', 'test', 'batch${i % 5}'],
          );
          await HiveNoteTakingRepo.addNote(note);
        }

        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds max

        // Step 2: Retrieve all notes
        stopwatch.reset();
        stopwatch.start();

        final allNotes = await HiveNoteTakingRepo.getNotes();
        expect(allNotes.length, equals(50));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1 second max

        // Step 3: Test concurrent operations
        stopwatch.reset();
        stopwatch.start();

        final futures = List.generate(10, (i) async {
          final note = NoteTakingModel(
            noteId: 'concurrent-note-$i',
            noteTitle: 'Concurrent Test $i',
            noteContent: 'Testing concurrent operations',
            userId: 'test-user',
          );
          await HiveNoteTakingRepo.addNote(note);
          return note.noteId;
        });

        final results = await Future.wait(futures);
        expect(results.length, equals(10));
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 2 seconds max

        stopwatch.stop();
      });
    });
  });
}
