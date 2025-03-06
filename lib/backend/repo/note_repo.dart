import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NoteTakingResult {
  final String? noteId;
  final String? error;
  final bool isSuccess;

  NoteTakingResult({this.noteId, this.error, required this.isSuccess});
}

class NoteTakingRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<NoteTakingResult> createNote(
      String noteTitle, String noteContent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return NoteTakingResult(
            noteId: null, error: "User not logged in.", isSuccess: false);
      }

      DocumentReference noteRef = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .add({
        'noteTitle': noteTitle,
        'noteContent': noteContent,
      });

      return NoteTakingResult(noteId: noteRef.id, error: null, isSuccess: true);
    } catch (e) {
      return NoteTakingResult(
          noteId: null, error: "Failed to create note: $e", isSuccess: false);
    }
  }

  Future<NoteTakingResult> updateNote(
      String noteId, String noteTitle, String noteContent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return NoteTakingResult(
            noteId: null, error: "User not logged in.", isSuccess: false);
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .update({
        'noteTitle': noteTitle,
        'noteContent': noteContent,
      });

      return NoteTakingResult(noteId: noteId, error: null, isSuccess: true);
    } catch (e) {
      return NoteTakingResult(
          noteId: null, error: "Failed to update note: $e", isSuccess: false);
    }
  }

  Future<NoteTakingResult> deleteNote(String noteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return NoteTakingResult(
            noteId: null, error: "User not logged in.", isSuccess: false);
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(noteId)
          .delete();

      return NoteTakingResult(noteId: noteId, error: null, isSuccess: true);
    } catch (e) {
      return NoteTakingResult(
          noteId: null, error: "Failed to delete note: $e", isSuccess: false);
    }
  }
}
