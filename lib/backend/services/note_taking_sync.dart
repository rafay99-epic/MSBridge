import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';
import 'dart:async';
import 'package:msbridge/backend/repo/auth_repo.dart';
import 'package:msbridge/backend/repo/hive_note_taking_repo.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthRepo _authRepo = AuthRepo();

  final StreamController<void> _noteChangeController =
      StreamController<void>.broadcast();

  Stream<void> get noteChanges => _noteChangeController.stream;

  SyncService() {
    _initHive();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    print("✅ Hive initialized");
  }

  Future<void> _onNoteChange() async {
    print("⚡ Note change detected, triggering sync...");
    await syncLocalNotesToFirebase();
  }

  Future<void> startListening() async {
    try {
      print("📦 Hive box listening starting");

      print("🔄 Performing initial sync...");
      await syncLocalNotesToFirebase();

      noteChanges.listen((_) => _onNoteChange());
      print("👂 Listening to note changes");
    } catch (e) {
      print("⚠️ Error starting Hive listener: $e");
    }
  }

  void dispose() {
    _noteChangeController.close();
    print("🛑 SyncService disposed");
  }

  Future<void> syncLocalNotesToFirebase() async {
    try {
      print("📦 Accessing Hive box (syncLocalNotesToFirebase)");

      List<NoteTakingModel> allNotes = await HiveNoteTakingRepo.getNotes();
      print("📝 Total notes in Hive: ${allNotes.length}");

      AuthResult authResult = await _authRepo.getCurrentUser();
      User? user = authResult.user;

      if (user == null) {
        print("⚠️ No user logged in. Cannot sync notes.");
        return;
      }
      String userId = user.uid;
      print("👤 User ID: $userId");

      List<NoteTakingModel> unsyncedNotes = allNotes
          .where((note) =>
              !note.isSynced && !note.isDeleted && note.userId == userId)
          .toList();
      print("⏳ Unsynced notes: ${unsyncedNotes.length}");

      for (var note in unsyncedNotes) {
        print(
            "Processing unsynced note: ${note.noteTitle}, ID: ${note.noteId}");
        try {
          CollectionReference userNotesCollection =
              _firestore.collection('users').doc(userId).collection('notes');
          print("🔥 Firestore collection path: ${userNotesCollection.path}");

          Map<String, dynamic> noteData = note.toMap();
          print("🗺️ Note data to sync: $noteData");

          if (note.noteId == null || note.noteId!.isEmpty) {
            print("➕ Creating new note in Firestore");
            var ref = await userNotesCollection.add(noteData);
            note.noteId = ref.id;
            print("🔑 New Firestore note ID: ${note.noteId}");
          } else {
            print(
                "✏️ Updating existing note in Firestore with ID: ${note.noteId}");
            await userNotesCollection.doc(note.noteId).set(noteData);
          }

          note.isSynced = true;
          await HiveNoteTakingRepo.updateNote(note);
          print("☁️ Synced: ${note.noteTitle}, ID: ${note.noteId}");
        } catch (e) {
          print("⚠️ Sync Failed for ${note.noteTitle}, ID: ${note.noteId}: $e");
        }
      }

      List<NoteTakingModel> deletedNotes = allNotes
          .where((note) =>
              note.isDeleted &&
              note.isSynced &&
              note.userId == userId &&
              note.noteId != null &&
              note.noteId!.isNotEmpty)
          .toList();
      print("🗑️ Deleted notes: ${deletedNotes.length}");

      for (var note in deletedNotes) {
        print(
            "Deleting note from Firestore: ${note.noteTitle}, ID: ${note.noteId}");
        try {
          CollectionReference userNotesCollection =
              _firestore.collection('users').doc(userId).collection('notes');
          print("🔥 Firestore collection path: ${userNotesCollection.path}");

          await userNotesCollection.doc(note.noteId).delete();
          print(
              "🗑️ Deleted from Firebase: ${note.noteTitle}, ID: ${note.noteId}");

          await HiveNoteTakingRepo.deleteNote(note);
          print("🗑️ Deleted from Hive: ${note.noteTitle}, ID: ${note.noteId}");
        } catch (e) {
          print(
              "⚠️ Delete from Firebase Failed for ${note.noteTitle}, ID: ${note.noteId}: $e");
        }
      }

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
              print(
                  "Comparing note: ${note.noteTitle}, ID: ${note.noteId}, Maps are equal: $mapsAreEqual");
              if (!mapsAreEqual) {
                updatedNotes.add(note);
              }
            } else {
              print(
                  "Note ${note.noteTitle}, ID: ${note.noteId} not found in Firestore, treating as new.");
              updatedNotes.add(note);
            }
          } catch (e) {
            print(
                "⚠️ Error comparing note ${note.noteTitle}, ID: ${note.noteId}: $e");
          }
        }
      }
      print("🔄 Updated notes: ${updatedNotes.length}");

      for (var note in updatedNotes) {
        print(
            "Updating note in Firestore: ${note.noteTitle}, ID: ${note.noteId}");
        try {
          CollectionReference userNotesCollection =
              _firestore.collection('users').doc(userId).collection('notes');
          print("🔥 Firestore collection path: ${userNotesCollection.path}");

          Map<String, dynamic> noteData = note.toMap();
          print("🗺️ Note data to update: $noteData");

          await userNotesCollection.doc(note.noteId).set(noteData);
          await HiveNoteTakingRepo.updateNote(note);
          print(
              "🔄 Updated in Firebase: ${note.noteTitle}, ID: ${note.noteId}");
        } catch (e) {
          print(
              "⚠️ Update in Firebase Failed for ${note.noteTitle}, ID: ${note.noteId}: $e");
        }
      }

      if (unsyncedNotes.isEmpty &&
          deletedNotes.isEmpty &&
          updatedNotes.isEmpty) {
        print("✅ All Notes Synced");
      }
    } catch (e) {
      print("⚠️ General Sync Error: $e");
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
