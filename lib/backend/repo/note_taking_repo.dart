import 'package:firebase_auth/firebase_auth.dart';
import 'package:msbridge/backend/hive/note_taking/note_taking.dart';
import 'package:msbridge/backend/repo/hive_note_taking_repo.dart';
import 'package:uuid/uuid.dart';

class NoteTakingActions {
  static String generateUuid() {
    const uuid = Uuid();
    return uuid.v4();
  }

  static Future<SaveNoteResult> saveNote({
    required String title,
    required String content,
  }) async {
    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;
      if (user == null) {
        return SaveNoteResult(
            success: false, message: "You must be logged in to save notes.");
      }
      String userId = user.uid;

      if (title.isNotEmpty || content.isNotEmpty) {
        String noteUUID = generateUuid();
        NoteTakingModel note = NoteTakingModel(
          noteId: noteUUID,
          noteTitle: title,
          noteContent: content,
          isSynced: false,
          isDeleted: false,
          updatedAt: DateTime.now(),
          userId: userId,
        );

        await HiveNoteTakingRepo.addNote(note);

        return SaveNoteResult(
            success: true, message: "Note Saved Successfully!");
      } else {
        return SaveNoteResult(
            success: false,
            message: "Sorry Content Not Saved! Enter Something to continue");
      }
    } catch (e) {
      return SaveNoteResult(success: false, message: "Error saving note: $e");
    }
  }
}

class SaveNoteResult {
  final bool success;
  final String message;

  SaveNoteResult({required this.success, required this.message});
}
