import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  }

  Future<void> startListening() async {
    try {
      // Check global sync toggle before syncing
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;
      await syncLocalNotesToFirebase();
    } catch (e) {
      throw Exception("⚠️ Error starting Hive listener: $e");
    }
  }

  Future<void> syncLocalNotesToFirebase() async {
    try {
      final enabled = await _isCloudSyncEnabled();
      if (!enabled) return;
      List<NoteTakingModel> allNotes = await HiveNoteTakingRepo.getNotes();
      Box<NoteTakingModel> deletedNotesBox =
          await HiveNoteTakingRepo.getDeletedBox();

      User? user = await _getCurrentUser();
      if (user == null) {
        throw Exception("⚠️ No user logged in. Cannot sync notes.");
      }
      String userId = user.uid;

      await _syncUnsyncedNotes(userId, allNotes);
      await _syncDeletedNotes(userId, deletedNotesBox);
      await _syncUpdatedNotes(userId, allNotes);
    } catch (e) {
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
        CollectionReference userNotesCollection =
            _firestore.collection('users').doc(userId).collection('notes');

        Map<String, dynamic> noteData = note.toMap();

        if (note.noteId == null || note.noteId!.isEmpty) {
          var ref = await userNotesCollection.add(noteData);
          note.noteId = ref.id;
        } else {
          await userNotesCollection.doc(note.noteId).set(noteData);
        }

        note.isSynced = true;
        await HiveNoteTakingRepo.updateNote(note);
      } catch (e) {
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
      if (note.isSynced && !note.isDeleted && note.userId == userId) {
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
        await HiveNoteTakingRepo.updateNote(note);
      } catch (e) {
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
