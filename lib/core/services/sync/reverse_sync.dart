import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/repo/note_version_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReverseSyncService {
  final AuthRepo _authRepo = AuthRepo();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HiveNoteTakingRepo hiveNoteTakingRepo = HiveNoteTakingRepo();

  Future<void> syncDataFromFirebaseToHive() async {
    try {
      try {
        await HiveNoteTakingRepo.getBox();
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: "Failed to initialize Hive notes box");
        throw Exception("Failed to initialize local storage: $e");
      }

      // Respect global cloud-sync user toggle (privacy choice)
      try {
        final enabled = await _isCloudSyncEnabled();
        if (!enabled) {
          return;
        }
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: "Sorry User, Cloud sync is disabled");
      }

      final userResult = await _authRepo.getCurrentUser();

      if (!userResult.isSuccess || userResult.user == null) {
        final errorMessage = userResult.error ?? "User not authenticated";
        FirebaseCrashlytics.instance.recordError(
            Exception(errorMessage), StackTrace.current,
            reason: "User not authenticated");
        throw Exception(errorMessage);
      }

      final user = userResult.user!;
      final userId = user.uid;

      // Incremental pull from cloud: only notes updated since last successful pull
      try {
        final userNotesCollection =
            _firestore.collection('users').doc(userId).collection('notes');

        // Load last successful reverse sync timestamp (ISO 8601 string)
        final prefs = await SharedPreferences.getInstance();
        final lastSyncKey = 'reverse_sync_last_ts_$userId';
        final String lastSyncIso =
            prefs.getString(lastSyncKey) ?? '1970-01-01T00:00:00Z';

        // Query only changed notes since last sync
        Query query = userNotesCollection
            .where('updatedAt', isGreaterThan: lastSyncIso)
            .orderBy('updatedAt', descending: false)
            .limit(100);
        QuerySnapshot notesSnapshot = await query.get();

        final box = await HiveNoteTakingRepo.getBox();
        DateTime newestSeen = DateTime.tryParse(lastSyncIso) ??
            DateTime.fromMillisecondsSinceEpoch(0);

        while (true) {
          final docs = notesSnapshot.docs;
          if (docs.isEmpty) break;
          const batchSize = 50;
          for (var i = 0; i < docs.length; i += batchSize) {
            final batch = docs.sublist(
                i, (i + batchSize < docs.length) ? i + batchSize : docs.length);

            final Map<String, NoteTakingModel> notesToAdd = {};
            for (final doc in batch) {
              final data = doc.data() as Map<String, dynamic>;

              // Skip deleted notes
              if (data['isDeleted'] == true) {
                continue;
              }

              // Handle date parsing more safely
              String updatedAtString;
              try {
                if (data['updatedAt'] != null) {
                  updatedAtString = data['updatedAt'].toString();
                  // Validate the date string
                  DateTime.parse(updatedAtString);
                } else {
                  updatedAtString = DateTime.now().toIso8601String();
                }
              } catch (e) {
                FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                    reason: "Invalid date format in cloud note");
                updatedAtString = DateTime.now().toIso8601String();
              }

              final noteMap = {
                'noteId': doc.id,
                'noteTitle': data['noteTitle'] ?? '',
                'noteContent': data['noteContent'] ?? '',
                'isSynced': true, // Mark as synced since it came from cloud
                'isDeleted': false,
                'updatedAt': updatedAtString,
                'userId': userId,
                'tags': (data['tags'] as List?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [],
                'versionNumber': data['versionNumber'] ?? 1,
                'createdAt': data['createdAt'] ?? updatedAtString,
              };

              try {
                final note = NoteTakingModel.fromMap(noteMap);
                notesToAdd[doc.id] = note;
              } catch (e) {
                FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                    reason: "Failed to create note from map");
                continue;
              }
            }

            // Upsert notes to Hive in batches (handle deletes)
            for (final entry in notesToAdd.entries) {
              final noteId = entry.key;
              final note = entry.value;
              try {
                // Track newest updatedAt we see for watermark
                if (note.updatedAt.isAfter(newestSeen)) {
                  newestSeen = note.updatedAt;
                }

                // Find existing local note
                NoteTakingModel? existing;
                for (int i = 0; i < box.length; i++) {
                  final n = box.getAt(i);
                  if (n?.noteId == noteId) {
                    existing = n;
                    break;
                  }
                }

                if (note.isDeleted) {
                  // Remove locally if present
                  if (existing != null) {
                    await HiveNoteTakingRepo.deleteNote(existing);
                    await NoteVersionRepo.clearVersionsForNote(noteId);
                  }
                } else {
                  if (existing != null) {
                    existing.noteTitle = note.noteTitle;
                    existing.noteContent = note.noteContent;
                    existing.tags = note.tags;
                    existing.isDeleted = false;
                    existing.isSynced = true;
                    existing.updatedAt = note.updatedAt;
                    existing.versionNumber = note.versionNumber;
                    await HiveNoteTakingRepo.updateNote(existing);
                  } else {
                    await HiveNoteTakingRepo.addNote(note);
                  }
                }
              } catch (e) {
                FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                    reason: "Failed to upsert note to Hive");
                continue;
              }
            }
          }

          final lastDoc = docs.last;
          notesSnapshot = await query.startAfterDocument(lastDoc).get();
        }

        try {
          final nextIso = newestSeen.toUtc().toIso8601String();
          await prefs.setString(lastSyncKey, nextIso);
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
              reason: "Failed to persist watermark");
        }

        // Sync versions from Firebase after notes are synced
        try {
          await _syncVersionsFromFirebase(userId);
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
              reason: "Failed to sync versions from Firebase");
        }

        // Force refresh the Hive box
        try {
          await box.flush();
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
              reason: "Failed to flush Hive box");
          // Continue anyway - flush failure shouldn't break the operation
        }
      } catch (firebaseError) {
        FirebaseCrashlytics.instance.recordError(
            firebaseError, StackTrace.current,
            reason: "Failed to fetch notes from cloud");
        throw Exception("Failed to fetch notes from cloud: $firebaseError");
      }
    } catch (authError) {
      FirebaseCrashlytics.instance.recordError(authError, StackTrace.current,
          reason: "Authentication failed");
      throw Exception("Authentication failed: $authError");
    }
  }

  Future<bool> _isCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('cloud_sync_enabled') ?? true;
  }

  /// Sync versions from Firebase for all notes
  Future<void> _syncVersionsFromFirebase(String userId) async {
    try {
      // Get all notes to sync their versions
      final notesCollection =
          _firestore.collection('users').doc(userId).collection('notes');

      final notesSnapshot = await notesCollection
          .orderBy('updatedAt', descending: true)
          .limit(100)
          .get();

      for (final noteDoc in notesSnapshot.docs) {
        final noteId = noteDoc.id;

        // Get versions subcollection for this note
        final versionsCollection = noteDoc.reference.collection('versions');
        final versionsSnapshot = await versionsCollection
            .orderBy('versionNumber', descending: true)
            .limit(100)
            .get();

        if (versionsSnapshot.docs.isNotEmpty) {
          // Clear existing local versions for this note
          await NoteVersionRepo.clearVersionsForNote(noteId);

          // Import versions from Firebase
          for (final versionDoc in versionsSnapshot.docs) {
            final data = versionDoc.data();
            await _importVersionFromFirebase(data, userId, noteId);
          }
        }
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Failed to sync versions from Firebase");
      throw Exception("Failed to sync versions from Firebase: $e");
    }
  }

  /// Import a version from Firebase
  Future<void> _importVersionFromFirebase(
      Map<String, dynamic> data, String userId, String noteId) async {
    try {
      // Validate required fields
      final noteIdFromData = data['noteId'] as String?;
      if (noteIdFromData == null || noteIdFromData.isEmpty) {
        return;
      }

      // Create version using the repo
      await NoteVersionRepo.createVersion(
        noteId: noteIdFromData,
        noteTitle: data['noteTitle'] ?? '',
        noteContent: data['noteContent'] ?? '',
        tags: List<String>.from(data['tags'] ?? []),
        userId: userId,
        versionNumber: data['versionNumber'] ?? 1,
        changeDescription: data['changeDescription'] ?? '',
        previousVersionId: data['previousVersionId'] ?? '',
      );
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error importing version from Firebase");
      // Continue with other versions
    }
  }

  // Get count of notes pulled from cloud
  Future<int> getCloudNotesCount() async {
    try {
      final userResult = await _authRepo.getCurrentUser();

      if (!userResult.isSuccess || userResult.user == null) {
        return 0;
      }

      final user = userResult.user!;
      final userId = user.uid;

      final userNotesCollection =
          _firestore.collection('users').doc(userId).collection('notes');

      final QuerySnapshot notesSnapshot = await userNotesCollection.get();

      // Count only non-deleted notes
      int count = 0;
      for (final doc in notesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['isDeleted'] != true) {
          count++;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  // Force refresh the notes list after pulling from cloud
  Future<void> refreshNotesList() async {
    try {
      // Get the Hive box and force a refresh
      final box = await HiveNoteTakingRepo.getBox();

      // Trigger a box change to refresh the UI
      await box.flush();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Failed to refresh notes list");
    }
  }
}
