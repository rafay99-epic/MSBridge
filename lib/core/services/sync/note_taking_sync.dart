// Package imports:
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/core/repo/note_version_repo.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepo _authRepo = AuthRepo();

  SyncService() {
    _initHive();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    // Ensure the notes box is open before proceeding
    await HiveNoteTakingRepo.getBox();
  }

  Future<void> startListening() async {
    try {
      // Ensure Hive is properly initialized first
      await _initHive();

      // Check global sync toggle before syncing
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;

      // Refresh Hive box state before syncing
      await _refreshHiveBoxState();

      await syncLocalNotesToFirebase();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error starting sync service");
      throw Exception("⚠️ Error starting sync service: $e");
    }
  }

  /// Stops any background sync/listeners.
  /// Currently a safe no-op as we don't keep long-lived subscriptions here,
  /// but we keep the API to allow rollback/cleanup from UI flows.
  Future<void> stopListening() async {
    try {
      // If you add stream subscriptions in the future, cancel them here.
      await Future<void>.value();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Error stopping sync service");
    }
  }

  Future<void> _refreshHiveBoxState() async {
    try {
      final box = await HiveNoteTakingRepo.getBox();
      await box.flush();
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Failed to refresh Hive box state");
      // Continue anyway - this is not critical
    }
  }

  Future<void> syncLocalNotesToFirebase() async {
    try {
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;

      // Get notes with better error handling
      List<NoteTakingModel> allNotes;
      Box<NoteTakingModel> deletedNotesBox;

      try {
        allNotes = await HiveNoteTakingRepo.getNotes();
        deletedNotesBox = await HiveNoteTakingRepo.getDeletedBox();
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: "Failed to access local notes");
        throw Exception("⚠️ Failed to access local notes: $e");
      }

      User? user = await _getCurrentUser();
      if (user == null) {
        throw Exception("⚠️ No user logged in. Cannot sync notes.");
      }
      String userId = user.uid;

      await _syncUnsyncedNotes(userId, allNotes);
      await _syncDeletedNotes(userId, deletedNotesBox);
      await _syncUpdatedNotes(userId, allNotes);

      // Sync versions for each note
      try {
        for (final note in allNotes) {
          if (note.noteId != null && note.userId == userId) {
            await _syncNoteVersions(userId, note.noteId!);
          }
        }
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: "Failed to sync note versions");
        // Don't fail the entire sync if version sync fails
      }
    } catch (e) {
      FirebaseCrashlytics.instance
          .recordError(e, StackTrace.current, reason: "General Sync Error");
      throw Exception("⚠️ General Sync Error: $e");
    }
  }

  Future<bool> _isCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('cloud_sync_enabled') ?? true;
  }

  Future<User?> _getCurrentUser() async {
    AuthResult authResult = await _authRepo.getCurrentUser();
    return authResult.user;
  }

  Future<void> _syncUnsyncedNotes(
      String userId, List<NoteTakingModel> allNotes) async {
    List<NoteTakingModel> unsyncedNotes = allNotes
        .where((note) =>
            !note.isSynced && !note.isDeleted && note.userId == userId)
        .toList();

    for (var note in unsyncedNotes) {
      try {
        // Skip notes without valid IDs
        if (note.noteId == null || note.noteId!.isEmpty) {
          continue;
        }

        CollectionReference userNotesCollection =
            _firestore.collection('users').doc(userId).collection('notes');

        Map<String, dynamic> noteData = note.toMap();

        await userNotesCollection.doc(note.noteId).set(noteData);

        // Re-fetch the note from Hive to ensure it has proper box association
        try {
          final box = await HiveNoteTakingRepo.getBox();
          final freshNote = box.get(note.noteId);
          if (freshNote != null) {
            freshNote.isSynced = true;
            await freshNote.save();
          }
        } catch (hiveError) {
          FirebaseCrashlytics.instance.recordError(
              hiveError, StackTrace.current,
              reason: "Failed to update note in Hive after unsynced sync");
          // Continue with Firebase sync even if Hive update fails
        }
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: "Sync Failed for ${note.noteTitle}, ID: ${note.noteId}");
        throw Exception(
            "⚠️ Sync Failed for ${note.noteTitle}, ID: ${note.noteId}: $e");
      }
    }
  }

  Future<void> _syncDeletedNotes(
      String userId, Box<NoteTakingModel> deletedNotesBox) async {
    final deletedNoteIds = <String>[];

    for (var note in deletedNotesBox.values) {
      if (note.isDeleted &&
          note.isSynced &&
          note.userId == userId &&
          note.noteId != null &&
          note.noteId!.isNotEmpty) {
        try {
          CollectionReference userNotesCollection =
              _firestore.collection('users').doc(userId).collection('notes');

          await userNotesCollection.doc(note.noteId).delete();
          deletedNoteIds.add(note.noteId!);

          await HiveNoteTakingRepo.deleteNote(note);
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
              reason:
                  "Delete from Firebase Failed for ${note.noteTitle}, ID: ${note.noteId}");
          throw Exception(
              "⚠️ Delete from Firebase Failed for ${note.noteTitle}, ID: ${note.noteId}: $e");
        }
      }
    }

    // Clean up versions for deleted notes
    if (deletedNoteIds.isNotEmpty) {
      try {
        for (final noteId in deletedNoteIds) {
          await _cleanupNoteVersions(userId, noteId);
        }
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason: "Failed to cleanup versions for deleted notes");
        // Don't fail the entire sync if version cleanup fails
      }
    }
  }

  /// Sync versions for a specific note
  Future<void> _syncNoteVersions(String userId, String noteId) async {
    try {
      final versions = await NoteVersionRepo.getNoteVersions(noteId);
      if (versions.isEmpty) return;

      final noteDocRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId);

      // Create versions subcollection
      final versionsCollection = noteDocRef.collection('versions');

      // Sync each version
      for (final version in versions) {
        final versionData = version.toMap();
        versionData['syncedAt'] = DateTime.now().toIso8601String();

        await versionsCollection.doc(version.versionId).set(versionData);
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Failed to sync versions for note $noteId");
      throw Exception("Failed to sync versions for note $noteId: $e");
    }
  }

  /// Clean up versions for a deleted note
  Future<void> _cleanupNoteVersions(String userId, String noteId) async {
    try {
      // Clean up local versions
      await NoteVersionRepo.clearVersionsForNote(noteId);

      // Clean up Firebase versions
      final noteDocRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId);

      final versionsCollection = noteDocRef.collection('versions');
      final versionsSnapshot = await versionsCollection.get();

      // Delete all versions in batch
      final batch = _firestore.batch();
      for (final doc in versionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (versionsSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
          reason: "Failed to cleanup versions for note $noteId");
      throw Exception("Failed to cleanup versions for note $noteId: $e");
    }
  }

  Future<void> _syncUpdatedNotes(
      String userId, List<NoteTakingModel> allNotes) async {
    List<NoteTakingModel> updatedNotes = [];
    for (var note in allNotes) {
      if (note.isSynced &&
          !note.isDeleted &&
          note.userId == userId &&
          note.noteId != null &&
          note.noteId!.isNotEmpty) {
        try {
          DocumentSnapshot snapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('notes')
              .doc(note.noteId)
              .get();

          if (snapshot.exists) {
            final firestoreData = snapshot.data() as Map<String, dynamic>;

            // Parse updatedAt from cloud and local
            DateTime parseUpdatedAt(dynamic value) {
              if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
              if (value is Timestamp) return value.toDate();
              if (value is String) {
                try {
                  return DateTime.parse(value);
                } catch (_) {
                  return DateTime.fromMillisecondsSinceEpoch(0);
                }
              }
              return DateTime.fromMillisecondsSinceEpoch(0);
            }

            final cloudUpdatedAt = parseUpdatedAt(firestoreData['updatedAt']);
            final localUpdatedAt = note.updatedAt;

            // Conflict resolution:
            // - If cloud >= local, keep cloud (update local)
            // - If local > cloud, push local (queue for update)
            if (!cloudUpdatedAt.isBefore(localUpdatedAt)) {
              try {
                // Update local from cloud
                final box = await HiveNoteTakingRepo.getBox();
                final fresh = box.get(note.noteId);
                if (fresh != null) {
                  fresh.noteTitle =
                      (firestoreData['noteTitle'] ?? '') as String;
                  fresh.noteContent =
                      (firestoreData['noteContent'] ?? '') as String;
                  final tags = (firestoreData['tags'] as List?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      <String>[];
                  fresh.tags = tags;
                  fresh.isDeleted =
                      (firestoreData['isDeleted'] ?? false) as bool;
                  fresh.isSynced = true;
                  // Use parsed cloud time or now if missing
                  fresh.updatedAt =
                      cloudUpdatedAt == DateTime.fromMillisecondsSinceEpoch(0)
                          ? DateTime.now()
                          : cloudUpdatedAt;
                  await fresh.save();

                  // Log conflict kept cloud
                  FirebaseCrashlytics.instance.log(
                      'Conflict resolved (kept cloud) for noteId=${note.noteId} cloudUpdatedAt=$cloudUpdatedAt localUpdatedAt=$localUpdatedAt');
                }
              } catch (e) {
                FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
                    reason:
                        'Failed applying cloud winner for note ${note.noteId}');
              }
            } else {
              // Local is newer → queue for pushing to cloud
              updatedNotes.add(note);
              FirebaseCrashlytics.instance.log(
                  'Conflict resolved (kept local) for noteId=${note.noteId} cloudUpdatedAt=$cloudUpdatedAt localUpdatedAt=$localUpdatedAt');
            }
          } else {
            // Not in cloud yet → push local
            updatedNotes.add(note);
          }
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
              reason:
                  "Error comparing note ${note.noteTitle}, ID: ${note.noteId}");
          throw Exception(
              "⚠️ Error comparing note ${note.noteTitle}, ID: ${note.noteId}: $e");
        }
      }
    }
    for (var note in updatedNotes) {
      try {
        CollectionReference userNotesCollection =
            _firestore.collection('users').doc(userId).collection('notes');

        Map<String, dynamic> noteData = note.toMap();

        await userNotesCollection.doc(note.noteId).set(noteData);

        // Re-fetch the note from Hive to ensure it has proper box association
        try {
          final box = await HiveNoteTakingRepo.getBox();
          final freshNote = box.get(note.noteId);
          if (freshNote != null) {
            // Update the fresh note with new data
            freshNote.isSynced = true;
            await freshNote.save();
          }
        } catch (hiveError) {
          FirebaseCrashlytics.instance.recordError(
              hiveError, StackTrace.current,
              reason: "Failed to update note in Hive after Firebase sync");
          // Continue with Firebase sync even if Hive update fails
        }
      } catch (e) {
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current,
            reason:
                "Update in Firebase Failed for ${note.noteTitle}, ID: ${note.noteId}");
        throw Exception(
            "⚠️ Update in Firebase Failed for ${note.noteTitle}, ID: ${note.noteId}: $e");
      }
    }
  }

  bool mapsEqual(Map map1, Map map2) {
    if (map1.length != map2.length) {
      return false;
    }
    for (var key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }
}
