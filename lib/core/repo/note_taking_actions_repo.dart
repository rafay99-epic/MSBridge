import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/repo/hive_note_taking_repo.dart';
import 'package:msbridge/utils/uuid.dart';

class NoteTakingActions {
  static Future<SaveNoteResult> saveNote({
    required String title,
    required String content,
    List<String> tags = const [],
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
          tags: tags,
        );

        await HiveNoteTakingRepo.addNote(note);

        return SaveNoteResult(
          success: true,
          message: "Note Saved Successfully!",
          note: note,
        );
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
    List<String>? tags,
  }) async {
    try {
      final List<String> newTags = tags ?? note.tags;
      if (note.noteTitle == title && note.noteContent == content && _listEquals(note.tags, newTags)) {
        return SaveNoteResult(success: true, message: "No changes detected.");
      }

      note.noteTitle = title;
      note.noteContent = content;
      note.updatedAt = DateTime.now();
      note.isSynced = isSynced;
      note.tags = newTags;

      await HiveNoteTakingRepo.updateNote(note);

      return SaveNoteResult(
        success: true,
        message: "Note Updated Successfully!",
        note: note,
      );
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
      final User? user = FirebaseAuth.instance.currentUser;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      bool hadError = false;

      for (final noteId in noteIds) {
        final NoteTakingModel noteToDelete = box.values.firstWhere(
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

        // Try to remove from Firebase first when possible
        if (user != null &&
            noteToDelete.noteId != null &&
            noteToDelete.noteId!.isNotEmpty) {
          try {
            await firestore
                .collection('users')
                .doc(user.uid)
                .collection('notes')
                .doc(noteToDelete.noteId)
                .delete();
          } catch (_) {
            hadError = true;
            // continue to remove locally regardless
          }
        }

        await HiveNoteTakingRepo.permantentlyDeleteNote(noteToDelete);
      }

      return SaveNoteResult(
        success: !hadError,
        message: hadError
            ? "Notes deleted locally; some may not be removed from server."
            : "Selected notes permanently deleted.",
      );
    } catch (e) {
      return SaveNoteResult(
          success: false, message: "Error deleting notes: $e");
    }
  }

  static Future<SaveNoteResult> permanentlyDeleteAllNotes() async {
    try {
      final box = await HiveNoteTakingRepo.getDeletedBox();
      final List<NoteTakingModel> allNotes = box.values.toList();
      final User? user = FirebaseAuth.instance.currentUser;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      bool hadError = false;

      for (final note in allNotes) {
        if (user != null && note.noteId != null && note.noteId!.isNotEmpty) {
          try {
            await firestore
                .collection('users')
                .doc(user.uid)
                .collection('notes')
                .doc(note.noteId)
                .delete();
          } catch (_) {
            hadError = true;
          }
        }
        await HiveNoteTakingRepo.permantentlyDeleteNote(note);
      }

      return SaveNoteResult(
        success: !hadError,
        message: hadError
            ? "Deleted locally; some notes may not be removed from server."
            : "All notes permanently deleted.",
      );
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

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class SaveNoteResult {
  final bool success;
  final String message;
  final NoteTakingModel? note;

  SaveNoteResult({required this.success, required this.message, this.note});
}
