import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:hive/hive.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth =
      FirebaseAuth.instance; // Get Firebase Auth instance

  Future<void> syncLocalNotesToFirebase() async {
    var box = await Hive.openBox<NoteTakingModel>('notes');
    List<NoteTakingModel> allNotes = box.values.toList();

    // Get the current user's ID.  This is essential!
    User? user = _auth.currentUser;
    if (user == null) {
      print("⚠️ No user logged in. Cannot sync notes.");
      return; // Or handle the case where the user is not logged in (e.g., redirect to login)
    }
    String userId = user.uid;

    // 1. Handle Updates and Creations
    List<NoteTakingModel> unsyncedNotes = allNotes
        .where((note) =>
            !note.isSynced && !note.isDeleted && note.userId == userId)
        .toList();

    if (unsyncedNotes.isNotEmpty) {
      for (var note in unsyncedNotes) {
        try {
          CollectionReference userNotesCollection = _firestore
              .collection('users')
              .doc(userId)
              .collection('notes'); // Reference to user's notes collection

          if (note.noteId == null) {
            // Create New Note
            DocumentReference ref = await userNotesCollection.add(note.toMap());
            note.noteId = ref.id;
          } else {
            // Update existing note
            await userNotesCollection
                .doc(note.noteId)
                .set(note.toMap()); // Update Firebase
          }

          note.isSynced = true;
          await note.save(); // Save updated isSynced and noteId to Hive
          print("☁️ Synced: ${note.noteTitle}");
        } catch (e) {
          print("⚠️ Sync Failed for ${note.noteTitle}: $e");
        }
      }
    } else {
      print("✅ All New/Updated Notes are Synced");
    }

    // 2. Handle Deletions
    List<NoteTakingModel> deletedNotes = allNotes
        .where(
            (note) => note.isDeleted && note.isSynced && note.userId == userId)
        .toList(); // Only delete notes already synced!

    if (deletedNotes.isNotEmpty) {
      for (var note in deletedNotes) {
        try {
          if (note.noteId != null) {
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('notes')
                .doc(note.noteId)
                .delete();
            print("🗑️ Deleted from Firebase: ${note.noteTitle}");
          }

          await box.delete(note.key);
        } catch (e) {
          print("⚠️ Failed to delete ${note.noteTitle} from Firebase: $e");
        }
      }
    } else {
      print("✅ No notes to delete.");
    }

    await box.close();
  }
}
