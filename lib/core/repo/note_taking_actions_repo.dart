import 'package:firebase_auth/firebase_auth.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/utils/uuid.dart';

class NoteTakingActions {
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

  static Future<SaveNoteResult> updateNote({
    required NoteTakingModel note,
    required String title,
    required String content,
    required bool isSynced,
  }) async {
    try {
      note.noteTitle = title;
      note.noteContent = content;
      note.updatedAt = DateTime.now();
      note.isSynced = isSynced;

      await HiveNoteTakingRepo.updateNote(note);

      return SaveNoteResult(
          success: true, message: "Note updated successfully");
    } catch (e) {
      return SaveNoteResult(success: false, message: "Error updating note: $e");
    }
  }

  static Future<SaveNoteResult> deleteSelectedNotes(
      List<String> noteIds) async {
    try {
      final box = await HiveNoteTakingRepo.getBox();

      for (final noteId in noteIds) {
        NoteTakingModel? noteToDelete = box.values.firstWhere(
          (note) => note.noteId == noteId,
          orElse: () => NoteTakingModel(
              noteId: '',
              noteTitle: '',
              noteContent: '',
              isSynced: false,
              isDeleted: false,
              updatedAt: DateTime.now(),
              userId: ''),
        );
        noteToDelete.isDeleted = true;
        if (noteToDelete.noteId!.isNotEmpty) {
          await HiveNoteTakingRepo.deleteNote(noteToDelete);
        }
      }

      return SaveNoteResult(
          success: true, message: "Notes moved to recycle bin");
    } catch (e) {
      return SaveNoteResult(
          success: false, message: "Error deleting notes: $e");
    }
  }

  static Future<SaveNoteResult> permanentlyDeleteSelectedNotes(
      List<String> noteIds) async {
    try {
      final box = await HiveNoteTakingRepo.getDeletedBox();
      for (final noteId in noteIds) {
        NoteTakingModel? noteToDelete = box.values.firstWhere(
          (note) => note.noteId == noteId,
          orElse: () => NoteTakingModel(
              noteId: '',
              noteTitle: '',
              noteContent: '',
              isSynced: false,
              isDeleted: false,
              updatedAt: DateTime.now(),
              userId: ''),
        );

        await HiveNoteTakingRepo.permantentlyDeleteNote(noteToDelete);
      }

      return SaveNoteResult(
          success: true, message: "Selected notes permanently deleted.");
    } catch (e) {
      return SaveNoteResult(
          success: false, message: "Error deleting notes: $e");
    }
  }

  static Future<SaveNoteResult> permanentlyDeleteAllNotes() async {
    try {
      final box = await HiveNoteTakingRepo.getDeletedBox();

      final allNotes = box.values.toList();
      for (final note in allNotes) {
        await HiveNoteTakingRepo.permantentlyDeleteNote(note);
      }

      return SaveNoteResult(
          success: true, message: "All notes permanently deleted.");
    } catch (e) {
      return SaveNoteResult(
          success: false, message: "Error deleting all notes: $e");
    }
  }

  static Future<SaveNoteResult> restoreSelectedNotes(
      List<String> noteIds) async {
    try {
      final deletedBox = await HiveNoteTakingRepo.getDeletedBox();
      for (final noteId in noteIds) {
        final noteToRestore = deletedBox.values.firstWhere(
          (note) => note.noteId == noteId,
          orElse: () => NoteTakingModel(
              noteId: '',
              noteTitle: '',
              noteContent: '',
              isSynced: false,
              isDeleted: false,
              updatedAt: DateTime.now(),
              userId: ''),
        );

        if (noteToRestore.noteId!.isNotEmpty) {
          noteToRestore.isDeleted = false;

          await HiveNoteTakingRepo.addNoteToMainBox(noteToRestore);

          await HiveNoteTakingRepo.permantentlyDeleteNote(noteToRestore);
        }
      }
      return SaveNoteResult(success: true, message: "Notes Restored");
    } catch (e) {
      return SaveNoteResult(
          success: false, message: "Error restoring notes: $e");
    }
  }
}

class SaveNoteResult {
  final bool success;
  final String message;

  SaveNoteResult({required this.success, required this.message});
}
