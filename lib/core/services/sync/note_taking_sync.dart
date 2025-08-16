import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/auth_repo.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          Map<String, dynamic> hiveData = note.toMap();

          DocumentSnapshot snapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('notes')
              .doc(note.noteId)
              .get();

          if (snapshot.exists) {
            Map<String, dynamic> firestoreData =
                snapshot.data() as Map<String, dynamic>;
            bool mapsAreEqual = _mapsEqual(hiveData, firestoreData);

            if (!mapsAreEqual) {
              updatedNotes.add(note);
            }
          } else {
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

  bool _mapsEqual(Map map1, Map map2) {
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
