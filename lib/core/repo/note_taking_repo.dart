import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive/hive.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/services/delete/deletion_sync_service.dart';
import 'package:msbridge/core/services/device_ID/device_id_service.dart';
import 'package:msbridge/core/repo/note_version_repo.dart';

class NoteTakingRepo {
  static const String _boxName = 'notes';
  static const String _deletedBoxName = 'deleted_notes';

  /// Get the notes box
  static Box<NoteTakingModel> get _notesBox =>
      Hive.box<NoteTakingModel>(_boxName);

  /// Get the deleted notes box
  static Box<NoteTakingModel> get _deletedBox =>
      Hive.box<NoteTakingModel>(_deletedBoxName);

  /// Add a new note
  static Future<void> addNote(NoteTakingModel note) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();
      note.deviceId = deviceId;
      note.lastSyncAt = DateTime.now();

      await _notesBox.add(note);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error adding note and the expection is $e',
      );
      rethrow;
    }
  }

  /// Update an existing note
  static Future<void> updateNote(NoteTakingModel note) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();
      note.deviceId = deviceId;
      note.updatedAt = DateTime.now();
      note.lastSyncAt = DateTime.now();

      await note.save();
    } catch (e) {
      print('Error updating note: $e');
      rethrow;
    }
  }

  /// Delete a note with proper sync handling
  static Future<void> deleteNote(NoteTakingModel note, String userId) async {
    try {
      // Use the deletion sync service to properly handle deletion
      await DeletionSyncService.markNoteAsDeleted(note, userId);

      // Also delete all versions for this note on soft delete
      if (note.noteId != null && note.noteId!.isNotEmpty) {
        await NoteVersionRepo.clearVersionsForNote(note.noteId!);
      }

      // Move note to deleted box
      await _moveToDeletedBox(note);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error deleting note and the expection is $e',
      );
      rethrow;
    }
  }

  /// Restore a deleted note
  static Future<void> restoreNote(NoteTakingModel note, String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Use the deletion sync service to properly handle restoration
      await DeletionSyncService.restoreNote(note, userId);

      // Move note back to main box
      await _moveToMainBox(note);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error restoring note and the expection is $e',
      );
      rethrow;
    }
  }

  /// Permanently delete a note (after cleanup period)
  static Future<void> permanentlyDeleteNote(
      NoteTakingModel note, String userId) async {
    try {
      // Ensure all versions for this note are removed locally
      if (note.noteId != null && note.noteId!.isNotEmpty) {
        await NoteVersionRepo.clearVersionsForNote(note.noteId!);
      }

      // Remove from deleted box
      await _deletedBox.delete(note.key);

      // Remove from Firebase if it exists there
      await DeletionSyncService.cleanupOldDeletedNotes(userId);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error permanently deleting note and the expection is $e',
      );
      rethrow;
    }
  }

  /// Move note to deleted box
  static Future<void> _moveToDeletedBox(NoteTakingModel note) async {
    try {
      // Remove from main box
      await note.delete();

      // Add to deleted box
      await _deletedBox.add(note);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error moving note to deleted box and the expection is $e',
      );
      rethrow;
    }
  }

  /// Move note back to main box
  static Future<void> _moveToMainBox(NoteTakingModel note) async {
    try {
      // Remove from deleted box
      await _deletedBox.delete(note.key);

      // Add back to main box
      await _notesBox.add(note);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error moving note back to main box and the expection is $e',
      );
      rethrow;
    }
  }

  /// Get all active notes (not deleted)
  static List<NoteTakingModel> getAllNotes() {
    return _notesBox.values.where((note) => !note.isDeleted).toList();
  }

  /// Get all deleted notes
  static List<NoteTakingModel> getDeletedNotes() {
    return _deletedBox.values.toList();
  }

  /// Get notes that need syncing
  static List<NoteTakingModel> getNotesForSync() {
    return _notesBox.values.where((note) => note.shouldSync).toList();
  }

  /// Get deleted notes that need syncing
  static List<NoteTakingModel> getDeletedNotesForSync() {
    return _deletedBox.values.where((note) => !note.isDeletionSynced).toList();
  }

  /// Sync deletions from Firebase
  static Future<List<String>> syncDeletionsFromFirebase(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final allNotes = getAllNotes();
      final deletedNoteIds =
          await DeletionSyncService.syncDeletionsFromFirebase(
        allNotes,
        userId,
      );

      // Move newly deleted notes to deleted box
      for (final noteId in deletedNoteIds) {
        final note = allNotes.firstWhere(
          (note) => note.noteId == noteId,
          orElse: () => NoteTakingModel(
            noteTitle: '',
            noteContent: '',
            userId: userId,
          ),
        );
        if (note.noteId != null) {
          await _moveToDeletedBox(note);
        }
      }

      return deletedNoteIds;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error syncing deletions from Firebase and the expection is $e',
      );
      rethrow;
    }
  }

  /// Resolve deletion conflicts
  static Future<void> resolveDeletionConflicts(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final allNotes = getAllNotes();
      await DeletionSyncService.resolveDeletionConflicts(allNotes, userId);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error resolving deletion conflicts and the expection is $e',
      );
      rethrow;
    }
  }

  /// Clean up old deleted notes
  static Future<void> cleanupOldDeletedNotes(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get notes that are permanently deleted
      final permanentlyDeletedNotes = _deletedBox.values
          .where((note) => note.isPermanentlyDeleted)
          .toList();

      // Permanently delete them
      for (final note in permanentlyDeletedNotes) {
        await permanentlyDeleteNote(note, userId);
      }

      // Clean up Firebase
      await DeletionSyncService.cleanupOldDeletedNotes(userId);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error cleaning up old deleted notes and the expection is $e',
      );
      rethrow;
    }
  }

  /// Get deletion statistics
  static Future<Map<String, dynamic>> getDeletionStats(String userId) async {
    try {
      final stats = await DeletionSyncService.getDeletionStats(userId);

      // Add local stats
      stats['localDeletedNotes'] = getDeletedNotes().length;
      stats['localActiveNotes'] = getAllNotes().length;

      return stats;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error getting deletion stats and the expection is $e',
      );
      return {
        'error': e.toString(),
        'localDeletedNotes': getDeletedNotes().length,
        'localActiveNotes': getAllNotes().length,
      };
    }
  }

  /// Search notes (excluding deleted ones)
  static List<NoteTakingModel> searchNotes(String query) {
    final allNotes = getAllNotes();
    if (query.isEmpty) return allNotes;

    final lowerQuery = query.toLowerCase();
    return allNotes.where((note) {
      return note.noteTitle.toLowerCase().contains(lowerQuery) ||
          note.noteContent.toLowerCase().contains(lowerQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get note by ID
  static NoteTakingModel? getNoteById(String noteId) {
    try {
      return _notesBox.values.firstWhere((note) => note.noteId == noteId);
    } catch (e) {
      return null;
    }
  }

  /// Get deleted note by ID
  static NoteTakingModel? getDeletedNoteById(String noteId) {
    try {
      return _deletedBox.values.firstWhere((note) => note.noteId == noteId);
    } catch (e) {
      return null;
    }
  }
}
