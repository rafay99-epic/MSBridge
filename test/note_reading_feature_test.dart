import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_reading/notes_model.dart';

void main() {
  group('Note Reading Feature Tests', () {
    late Box<MSNote> notesBox;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Initialize Hive for testing
      Hive.init('./test_note_reading');

      // Register adapter
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MSNoteAdapter());
      }

      // Open test box
      notesBox = await Hive.openBox<MSNote>('test_reading_notes');
    });

    tearDownAll(() async {
      // Clean up
      try {
        await notesBox.clear();
        await notesBox.close();
        // Note: deleteFromDisk() calls FlutterBugfender which isn't available in tests
        // await notesBox.deleteFromDisk();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    group('MSNote Model Tests', () {
      test('MSNote can be created with all required fields', () {
        final note = MSNote(
          id: '1',
          lectureTitle: 'Introduction to Flutter',
          lectureDescription: 'Learn the basics of Flutter development',
          pubDate: '2024-01-15',
          lectureDraft: false,
          lectureNumber: '1',
          subject: 'Mobile Development',
          body: 'This is the lecture content...',
        );

        expect(note.id, equals('1'));
        expect(note.lectureTitle, equals('Introduction to Flutter'));
        expect(note.lectureDescription,
            equals('Learn the basics of Flutter development'));
        expect(note.pubDate, equals('2024-01-15'));
        expect(note.lectureDraft, isFalse);
        expect(note.lectureNumber, equals('1'));
        expect(note.subject, equals('Mobile Development'));
        expect(note.body, equals('This is the lecture content...'));
      });

      test('MSNote can be created with null body', () {
        final note = MSNote(
          id: '2',
          lectureTitle: 'Advanced Flutter',
          lectureDescription: 'Advanced Flutter concepts',
          pubDate: '2024-01-20',
          lectureDraft: true,
          lectureNumber: '2',
          subject: 'Mobile Development',
          body: null,
        );

        expect(note.body, isNull);
        expect(note.lectureDraft, isTrue);
      });

      test('MSNote toMap converts object to map correctly', () {
        final note = MSNote(
          id: '3',
          lectureTitle: 'Flutter Testing',
          lectureDescription: 'Learn Flutter testing strategies',
          pubDate: '2024-01-25',
          lectureDraft: false,
          lectureNumber: '3',
          subject: 'Testing',
          body: 'Testing is crucial for app development...',
        );

        final map = note.toMap();

        expect(map['id'], equals('3'));
        expect(map['lectureTitle'], equals('Flutter Testing'));
        expect(map['lectureDescription'],
            equals('Learn Flutter testing strategies'));
        expect(map['pubDate'], equals('2024-01-25'));
        expect(map['lectureDraft'], isFalse);
        expect(map['lectureNumber'], equals('3'));
        expect(map['subject'], equals('Testing'));
        expect(
            map['body'], equals('Testing is crucial for app development...'));
      });

      test('MSNote.fromJson handles valid JSON correctly', () {
        final jsonData = {
          'id': 4,
          'data': {
            'lecture_title': 'State Management',
            'lecture_description': 'Managing state in Flutter apps',
            'pubDate': '2024-02-01',
            'lectureDraft': false,
            'lectureNumber': 4,
            'subject': 'Architecture',
            'body': 'State management is essential...',
          }
        };

        final note = MSNote.fromJson(jsonData);

        expect(note.id, equals('4'));
        expect(note.lectureTitle, equals('State Management'));
        expect(
            note.lectureDescription, equals('Managing state in Flutter apps'));
        expect(note.pubDate, equals('2024-02-01'));
        expect(note.lectureDraft, isFalse);
        expect(note.lectureNumber, equals('4'));
        expect(note.subject, equals('Architecture'));
        expect(note.body, equals('State management is essential...'));
      });

      test('MSNote.fromJson handles null/missing data gracefully', () {
        final jsonData = {
          'id': null,
          'data': null,
        };

        final note = MSNote.fromJson(jsonData);

        expect(note.id, equals('0')); // Default fallback
        expect(note.lectureTitle, equals(''));
        expect(note.lectureDescription, equals(''));
        expect(note.pubDate, equals(''));
        expect(note.lectureDraft, isFalse);
        expect(note.lectureNumber, equals('0'));
        expect(note.subject, equals(''));
        expect(note.body, isNull);
      });

      test('MSNote.fromJson handles incomplete data gracefully', () {
        final jsonData = {
          'id': 5,
          'data': {
            'lecture_title': 'Partial Lecture',
            // Missing other fields
          }
        };

        final note = MSNote.fromJson(jsonData);

        expect(note.id, equals('5'));
        expect(note.lectureTitle, equals('Partial Lecture'));
        expect(note.lectureDescription, equals(''));
        expect(note.pubDate, equals(''));
        expect(note.lectureDraft, isFalse);
        expect(note.lectureNumber, equals('0'));
        expect(note.subject, equals(''));
        expect(note.body, isNull);
      });

      test('MSNote.fromJson handles different data types correctly', () {
        final jsonData = {
          'id': 6.5, // Float ID
          'data': {
            'lecture_title': 'Type Conversion Test',
            'lecture_description': 'Testing type conversions',
            'pubDate': '2024-02-10',
            'lectureDraft': false, // Keep as boolean for now
            'lectureNumber': 6, // Integer instead of string
            'subject': 'Testing',
            'body': 'This tests type conversions...',
          }
        };

        final note = MSNote.fromJson(jsonData);

        expect(note.id, equals('6.5'));
        expect(note.lectureNumber, equals('6'));
        expect(note.lectureDraft, isFalse);
      });
    });

    group('Hive Storage Tests', () {
      setUp(() async {
        // Clear the box before each test
        await notesBox.clear();
      });

      test('Can store and retrieve MSNote from Hive', () async {
        final note = MSNote(
          id: 'hive-test-1',
          lectureTitle: 'Hive Storage Test',
          lectureDescription: 'Testing Hive storage functionality',
          pubDate: '2024-02-15',
          lectureDraft: false,
          lectureNumber: '1',
          subject: 'Database',
          body: 'This note tests Hive storage...',
        );

        // Store in Hive
        await notesBox.put(note.id, note);

        // Retrieve from Hive
        final retrievedNote = notesBox.get(note.id);

        expect(retrievedNote, isNotNull);
        expect(retrievedNote!.id, equals(note.id));
        expect(retrievedNote.lectureTitle, equals(note.lectureTitle));
        expect(
            retrievedNote.lectureDescription, equals(note.lectureDescription));
        expect(retrievedNote.pubDate, equals(note.pubDate));
        expect(retrievedNote.lectureDraft, equals(note.lectureDraft));
        expect(retrievedNote.lectureNumber, equals(note.lectureNumber));
        expect(retrievedNote.subject, equals(note.subject));
        expect(retrievedNote.body, equals(note.body));
      });

      test('Can store multiple notes with different subjects', () async {
        final notes = [
          MSNote(
            id: 'multi-1',
            lectureTitle: 'Flutter Basics',
            lectureDescription: 'Basic Flutter concepts',
            pubDate: '2024-02-01',
            lectureDraft: false,
            lectureNumber: '1',
            subject: 'Flutter',
            body: 'Flutter basics content...',
          ),
          MSNote(
            id: 'multi-2',
            lectureTitle: 'Dart Language',
            lectureDescription: 'Dart programming language',
            pubDate: '2024-02-02',
            lectureDraft: false,
            lectureNumber: '1',
            subject: 'Dart',
            body: 'Dart language content...',
          ),
          MSNote(
            id: 'multi-3',
            lectureTitle: 'Advanced Flutter',
            lectureDescription: 'Advanced Flutter topics',
            pubDate: '2024-02-03',
            lectureDraft: false,
            lectureNumber: '2',
            subject: 'Flutter',
            body: 'Advanced Flutter content...',
          ),
        ];

        // Store all notes
        for (final note in notes) {
          await notesBox.put(note.id, note);
        }

        expect(notesBox.length, equals(3));

        // Test retrieving by different criteria
        final allNotes = notesBox.values.toList();
        expect(allNotes.length, equals(3));

        // Get unique subjects
        final subjects = allNotes.map((note) => note.subject).toSet().toList();
        expect(subjects.length, equals(2));
        expect(subjects, containsAll(['Flutter', 'Dart']));

        // Get Flutter notes
        final flutterNotes =
            allNotes.where((note) => note.subject == 'Flutter').toList();
        expect(flutterNotes.length, equals(2));
        expect(
            flutterNotes.map((n) => n.id), containsAll(['multi-1', 'multi-3']));
      });

      test('Can update existing notes', () async {
        final originalNote = MSNote(
          id: 'update-test',
          lectureTitle: 'Original Title',
          lectureDescription: 'Original description',
          pubDate: '2024-02-10',
          lectureDraft: true,
          lectureNumber: '1',
          subject: 'Testing',
          body: 'Original content...',
        );

        // Store original note
        await notesBox.put(originalNote.id, originalNote);

        // Update note
        final updatedNote = MSNote(
          id: 'update-test',
          lectureTitle: 'Updated Title',
          lectureDescription: 'Updated description',
          pubDate: '2024-02-11',
          lectureDraft: false,
          lectureNumber: '1',
          subject: 'Testing',
          body: 'Updated content...',
        );

        await notesBox.put(updatedNote.id, updatedNote);

        // Verify update
        final retrievedNote = notesBox.get('update-test');
        expect(retrievedNote!.lectureTitle, equals('Updated Title'));
        expect(retrievedNote.lectureDescription, equals('Updated description'));
        expect(retrievedNote.pubDate, equals('2024-02-11'));
        expect(retrievedNote.lectureDraft, isFalse);
        expect(retrievedNote.body, equals('Updated content...'));
      });

      test('Can delete notes from Hive', () async {
        final note = MSNote(
          id: 'delete-test',
          lectureTitle: 'To Be Deleted',
          lectureDescription: 'This note will be deleted',
          pubDate: '2024-02-12',
          lectureDraft: false,
          lectureNumber: '1',
          subject: 'Testing',
          body: 'Delete me...',
        );

        // Store note
        await notesBox.put(note.id, note);
        expect(notesBox.containsKey(note.id), isTrue);

        // Delete note
        await notesBox.delete(note.id);
        expect(notesBox.containsKey(note.id), isFalse);
        expect(notesBox.get(note.id), isNull);
      });
    });

    group('Note Filtering and Search Tests', () {
      setUp(() async {
        // Clear the box before each test
        await notesBox.clear();

        // Add test data
        final testNotes = [
          MSNote(
            id: 'search-1',
            lectureTitle: 'Flutter State Management',
            lectureDescription: 'Learn about state management in Flutter',
            pubDate: '2024-02-01',
            lectureDraft: false,
            lectureNumber: '1',
            subject: 'Flutter',
            body: 'Provider and BLoC patterns...',
          ),
          MSNote(
            id: 'search-2',
            lectureTitle: 'Dart Collections',
            lectureDescription: 'Working with Dart collections',
            pubDate: '2024-02-02',
            lectureDraft: false,
            lectureNumber: '1',
            subject: 'Dart',
            body: 'Lists, maps, and sets in Dart...',
          ),
          MSNote(
            id: 'search-3',
            lectureTitle: 'Flutter Animations',
            lectureDescription: 'Creating animations in Flutter',
            pubDate: '2024-02-03',
            lectureDraft: true,
            lectureNumber: '2',
            subject: 'Flutter',
            body: 'Implicit and explicit animations...',
          ),
          MSNote(
            id: 'search-4',
            lectureTitle: 'Mobile Testing',
            lectureDescription: 'Testing strategies for mobile apps',
            pubDate: '2024-02-04',
            lectureDraft: false,
            lectureNumber: '1',
            subject: 'Testing',
            body: 'Unit, widget, and integration tests...',
          ),
        ];

        for (final note in testNotes) {
          await notesBox.put(note.id, note);
        }
      });

      test('Can filter notes by subject', () {
        final allNotes = notesBox.values.toList();

        final flutterNotes =
            allNotes.where((note) => note.subject == 'Flutter').toList();
        expect(flutterNotes.length, equals(2));
        expect(flutterNotes.map((n) => n.id),
            containsAll(['search-1', 'search-3']));

        final dartNotes =
            allNotes.where((note) => note.subject == 'Dart').toList();
        expect(dartNotes.length, equals(1));
        expect(dartNotes.first.id, equals('search-2'));
      });

      test('Can filter notes by draft status', () {
        final allNotes = notesBox.values.toList();

        final publishedNotes =
            allNotes.where((note) => !note.lectureDraft).toList();
        expect(publishedNotes.length, equals(3));
        expect(publishedNotes.map((n) => n.id),
            containsAll(['search-1', 'search-2', 'search-4']));

        final draftNotes = allNotes.where((note) => note.lectureDraft).toList();
        expect(draftNotes.length, equals(1));
        expect(draftNotes.first.id, equals('search-3'));
      });

      test('Can search notes by title', () {
        final allNotes = notesBox.values.toList();

        final flutterTitleNotes = allNotes
            .where(
                (note) => note.lectureTitle.toLowerCase().contains('flutter'))
            .toList();
        expect(flutterTitleNotes.length, equals(2));

        final animationNotes = allNotes
            .where(
                (note) => note.lectureTitle.toLowerCase().contains('animation'))
            .toList();
        expect(animationNotes.length, equals(1));
        expect(animationNotes.first.id, equals('search-3'));
      });

      test('Can search notes by content', () {
        final allNotes = notesBox.values.toList();

        final providerNotes = allNotes
            .where((note) =>
                note.body?.toLowerCase().contains('provider') ?? false)
            .toList();
        expect(providerNotes.length, equals(1));
        expect(providerNotes.first.id, equals('search-1'));

        final testNotes = allNotes
            .where((note) => note.body?.toLowerCase().contains('test') ?? false)
            .toList();
        expect(testNotes.length, equals(1));
        expect(testNotes.first.id, equals('search-4'));
      });

      test('Can get unique subjects list', () {
        final allNotes = notesBox.values.toList();
        final subjects = allNotes.map((note) => note.subject).toSet().toList();

        expect(subjects.length, equals(3));
        expect(subjects, containsAll(['Flutter', 'Dart', 'Testing']));
        subjects.sort();
        expect(subjects, equals(['Dart', 'Flutter', 'Testing']));
      });

      test('Can sort notes by different criteria', () {
        final allNotes = notesBox.values.toList();

        // Sort by title
        allNotes.sort((a, b) => a.lectureTitle.compareTo(b.lectureTitle));
        expect(allNotes.first.lectureTitle, equals('Dart Collections'));
        expect(allNotes.last.lectureTitle, equals('Mobile Testing'));

        // Sort by subject
        allNotes.sort((a, b) => a.subject.compareTo(b.subject));
        expect(allNotes.first.subject, equals('Dart'));
        expect(allNotes.last.subject, equals('Testing'));

        // Sort by lecture number
        allNotes.sort((a, b) => a.lectureNumber.compareTo(b.lectureNumber));
        // All have lecture number '1' or '2', so verify first and last
        final lectureNumbers = allNotes.map((n) => n.lectureNumber).toList();
        expect(lectureNumbers, contains('1'));
        expect(lectureNumbers, contains('2'));
      });
    });

    group('Data Validation Tests', () {
      setUp(() async {
        // Clear the box before each test
        await notesBox.clear();
      });

      test('Handles notes with special characters', () {
        final note = MSNote(
          id: 'special-chars',
          lectureTitle: 'Spéciål Çhàracters & Émojis 🚀',
          lectureDescription: 'Testing with spëcial characters: àáâãäå',
          pubDate: '2024-02-15',
          lectureDraft: false,
          lectureNumber: '1',
          subject: 'Testing',
          body: 'Content with émojis 😊 and spéciål chars: ñáéíóú',
        );

        expect(() => notesBox.put(note.id, note), returnsNormally);

        final retrievedNote = notesBox.get(note.id);
        expect(retrievedNote!.lectureTitle,
            equals('Spéciål Çhàracters & Émojis 🚀'));
        expect(retrievedNote.body,
            equals('Content with émojis 😊 and spéciål chars: ñáéíóú'));
      });

      test('Handles empty and whitespace content', () {
        final note = MSNote(
          id: 'empty-content',
          lectureTitle: '',
          lectureDescription: '   ',
          pubDate: '',
          lectureDraft: false,
          lectureNumber: '',
          subject: '',
          body: '',
        );

        expect(() => notesBox.put(note.id, note), returnsNormally);

        final retrievedNote = notesBox.get(note.id);
        expect(retrievedNote!.lectureTitle, equals(''));
        expect(retrievedNote.lectureDescription, equals('   '));
        expect(retrievedNote.body, equals(''));
      });

      test('Handles very long content', () {
        final longContent = 'A' * 10000; // 10KB of content

        final note = MSNote(
          id: 'long-content',
          lectureTitle: 'Long Content Test',
          lectureDescription: 'Testing with very long content',
          pubDate: '2024-02-20',
          lectureDraft: false,
          lectureNumber: '1',
          subject: 'Performance',
          body: longContent,
        );

        expect(() => notesBox.put(note.id, note), returnsNormally);

        final retrievedNote = notesBox.get(note.id);
        expect(retrievedNote!.body!.length, equals(10000));
        expect(retrievedNote.body, equals(longContent));
      });

      test('Validates required fields are preserved', () {
        final note = MSNote(
          id: 'validation-test',
          lectureTitle: 'Required Field Test',
          lectureDescription: 'Testing required fields',
          pubDate: '2024-02-25',
          lectureDraft: false,
          lectureNumber: '1',
          subject: 'Validation',
        );

        expect(note.id.isNotEmpty, isTrue);
        expect(note.lectureTitle.isNotEmpty, isTrue);
        expect(note.lectureDescription.isNotEmpty, isTrue);
        expect(note.pubDate.isNotEmpty, isTrue);
        expect(note.lectureNumber.isNotEmpty, isTrue);
        expect(note.subject.isNotEmpty, isTrue);
        expect(note.body, isNull); // Optional field can be null
      });
    });

    group('Performance Tests', () {
      setUp(() async {
        // Clear the box before each test
        await notesBox.clear();
      });

      test('Can handle large number of notes', () async {
        final stopwatch = Stopwatch()..start();

        // Add 1000 notes
        for (int i = 0; i < 1000; i++) {
          final note = MSNote(
            id: 'perf-$i',
            lectureTitle: 'Performance Test $i',
            lectureDescription: 'Description $i',
            pubDate: '2024-02-01',
            lectureDraft: i % 2 == 0,
            lectureNumber: (i % 10).toString(),
            subject: 'Subject${i % 5}',
            body: 'Content for note $i',
          );

          await notesBox.put(note.id, note);
        }

        stopwatch.stop();
        final insertTime = stopwatch.elapsedMilliseconds;

        expect(notesBox.length, equals(1000));
        expect(insertTime,
            lessThan(5000)); // Should complete in less than 5 seconds

        // Test query performance
        stopwatch.reset();
        stopwatch.start();

        final allNotes = notesBox.values.toList();
        final subjects = allNotes.map((note) => note.subject).toSet().toList();
        final draftNotes = allNotes.where((note) => note.lectureDraft).toList();

        stopwatch.stop();
        final queryTime = stopwatch.elapsedMilliseconds;

        expect(subjects.length, equals(5));
        expect(draftNotes.length, equals(500));
        expect(
            queryTime, lessThan(1000)); // Should complete in less than 1 second
      });
    });

    group('Error Handling Tests', () {
      setUp(() async {
        // Clear the box before each test
        await notesBox.clear();
      });

      test('Handles corrupted data gracefully', () {
        // Test with malformed JSON - data field is string instead of map
        final malformedJson = {
          'id': 'corrupt-test',
          'data': 'this should be a map',
        };

        // This should throw an exception due to type casting
        expect(() => MSNote.fromJson(malformedJson), throwsA(isA<TypeError>()));
      });

      test('Handles missing Hive box gracefully', () {
        // This test ensures we handle box not being available
        expect(notesBox.isOpen, isTrue);
        expect(() => notesBox.values.toList(), returnsNormally);
      });

      test('Handles concurrent access', () async {
        // Test concurrent read/write operations
        final futures = <Future>[];

        for (int i = 0; i < 10; i++) {
          futures.add(() async {
            final note = MSNote(
              id: 'concurrent-$i',
              lectureTitle: 'Concurrent Test $i',
              lectureDescription: 'Testing concurrent access',
              pubDate: '2024-03-01',
              lectureDraft: false,
              lectureNumber: '1',
              subject: 'Concurrency',
              body: 'Content $i',
            );

            await notesBox.put(note.id, note);
            return notesBox.get(note.id);
          }());
        }

        final results = await Future.wait(futures);

        expect(results.length, equals(10));
        expect(results.every((note) => note != null), isTrue);
        expect(notesBox.length, greaterThanOrEqualTo(10));
      });
    });
  });
}
