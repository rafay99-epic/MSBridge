import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncLocalNotesToFirebase() async {
    var box = await Hive.openBox<NoteTakingModel>('notes');
    List<NoteTakingModel> unsyncedNotes =
        box.values.where((note) => !note.isSynced && !note.isDeleted).toList();

    if (unsyncedNotes.isEmpty) {
      print("✅ All Notes are Synced");
      return;
    }

    for (var note in unsyncedNotes) {
      try {
        if (note.noteId == null) {
          // Create New Note
          DocumentReference ref =
              await _firestore.collection('notes').add(note.toMap());
          note.noteId = ref.id;
        } else {
          await _firestore
              .collection('notes')
              .doc(note.noteId)
              .set(note.toMap());
        }

        note.isSynced = true;
        await note.save();
        print("☁️ Synced: ${note.noteTitle}");
      } catch (e) {
        print("⚠️ Sync Failed for ${note.noteTitle}: $e");
      }
    }
  }
}
