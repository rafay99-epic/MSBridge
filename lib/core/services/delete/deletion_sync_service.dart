import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/services/device_ID/device_id_service.dart';

class DeletionSyncService {
  static const String _usersCollection = 'users';
  static const String _deletedNotesCollection = 'deleted_notes';
  static const String _notesCollection = 'notes';
  static const Duration _cleanupThreshold = Duration(days: 30);

  /// Mark a note as deleted and sync to Firebase
  static Future<void> markNoteAsDeleted(
    NoteTakingModel note,
    String userId,
  ) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();

      // Mark note as deleted locally
      note.markAsDeleted(deviceId, userId);

static Future<void> markNoteAsDeleted(
  NoteTakingModel note,
  String userId,
) async {
  try {
    final deviceId = await DeviceIdService.getDeviceId();

    // Mark note as deleted locally
    note.markAsDeleted(deviceId, userId);

    // If note has no remote id yet, defer remote sync
    if (note.noteId == null || note.noteId!.isEmpty) {
      note.isDeletionSynced = false;
      return;
    }
    // Add to deleted notes collection in Firebase
    await _addToDeletedNotesCollection(note, userId, deviceId);
    // Update the note in Firebase to mark as deleted
    await _updateNoteDeletionStatus(note, userId);
  } catch (e) {
    // If Firebase sync fails, keep local deletion but mark for retry
    note.isDeletionSynced = false;
    rethrow;
  }
}
  }

  /// Restore a deleted note
  static Future<void> restoreNote(
    NoteTakingModel note,
    String userId,
  ) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();

      // Restore note locally
      note.restore();

      // Remove from deleted notes collection
      await _removeFromDeletedNotesCollection(userId, note.noteId!);

      // Update note in Firebase to remove deletion status
      await _updateNoteRestorationStatus(note, userId);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error restoring note and the expection is $e',
      );
      // If Firebase sync fails, keep local restoration but mark for retry
      note.isSynced = false;
      rethrow;
    }
  }

  /// Sync deletions from Firebase to local storage
  static Future<List<String>> syncDeletionsFromFirebase(
    List<NoteTakingModel> localNotes,
    String userId,
  ) async {
    try {
      final deletedNoteIds = <String>[];
      final firestore = FirebaseFirestore.instance;

      // Get all deleted notes from Firebase
      final deletedNotesSnapshot = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_deletedNotesCollection)
          .get();

      for (final deletedNoteDoc in deletedNotesSnapshot.docs) {
        final deletedNoteData = deletedNoteDoc.data();
        final noteId = deletedNoteData['noteId'] as String;
        final deletedAt = (deletedNoteData['deletedAt'] as Timestamp).toDate();
        final deletedBy = deletedNoteData['deletedBy'] as String;
        final deviceId = deletedNoteData['deviceId'] as String;

        // Find local note
        final localNote = localNotes.firstWhere(
          (note) => note.noteId == noteId,
          orElse: () => NoteTakingModel(
            noteTitle: '',
            noteContent: '',
            userId: userId,
          ),
        );

        // Check if this deletion is newer than local state
        if (localNote.noteId != null) {
          final shouldApplyDeletion = _shouldApplyDeletion(
            localNote,
            deletedAt,
            deletedBy,
            deviceId,
          );

          if (shouldApplyDeletion) {
            // Apply deletion locally
            localNote.markAsDeleted(deviceId, deletedBy);
            localNote.isDeletionSynced = true;
            deletedNoteIds.add(noteId);
          }
        }
      }

      return deletedNoteIds;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error syncing deletions from Firebase and the expection is $e',
      );
      // Log error but don't fail sync
      return [];
    }
  }

  /// Check if a deletion should be applied based on conflict resolution rules
  static bool _shouldApplyDeletion(
    NoteTakingModel localNote,
    DateTime deletedAt,
    String deletedBy,
    String deviceId,
  ) {
    // If note is not deleted locally, apply deletion
    if (!localNote.isDeleted) return true;

    // If local deletion is older, apply remote deletion
    if (localNote.deletedAt != null &&
        localNote.deletedAt!.isBefore(deletedAt)) {
      return true;
    }

    // If same device, apply deletion (local device made the change)
    if (localNote.deviceId == deviceId) return true;

    // If different device but remote deletion is newer, apply it
    if (localNote.deletedAt != null &&
        localNote.deletedAt!.isBefore(deletedAt)) {
      return true;
    }

    return false;
  }

  /// Add note to deleted notes collection
  static Future<void> _addToDeletedNotesCollection(
    NoteTakingModel note,
    String userId,
    String deviceId,
  ) async {
    final firestore = FirebaseFirestore.instance;

    await firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_deletedNotesCollection)
        .doc(note.noteId)
        .set({
      'noteId': note.noteId,
      'deletedAt': Timestamp.now(),
      'deletedBy': userId,
      'deviceId': deviceId,
      'noteTitle': note.noteTitle, // Keep for reference
      'noteContent': note.noteContent
          .substring(0, note.noteContent.length.clamp(0, 100)), // Keep snippet
    });
  }

  /// Remove note from deleted notes collection
  static Future<void> _removeFromDeletedNotesCollection(
      String userId, String noteId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_deletedNotesCollection)
        .doc(noteId)
        .delete();
  }

  /// Update note deletion status in Firebase
  static Future<void> _updateNoteDeletionStatus(
    NoteTakingModel note,
    String userId,
  ) async {
    final firestore = FirebaseFirestore.instance;

    await firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notesCollection)
        .doc(note.noteId)
        .update({
      'isDeleted': true,
      'deletedAt': Timestamp.now(),
      'deletedBy': userId,
      'deviceId': await DeviceIdService.getDeviceId(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Update note restoration status in Firebase
  static Future<void> _updateNoteRestorationStatus(
    NoteTakingModel note,
    String userId,
  ) async {
    final firestore = FirebaseFirestore.instance;

    await firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_notesCollection)
        .doc(note.noteId)
        .update({
      'isDeleted': false,
      'deletedAt': FieldValue.delete(),
      'deletedBy': FieldValue.delete(),
      'deviceId': FieldValue.delete(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Clean up old deleted notes (older than threshold)
  static Future<void> cleanupOldDeletedNotes(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final cleanupDate = DateTime.now().subtract(_cleanupThreshold);

      // Get old deleted notes
      final oldDeletedNotes = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_deletedNotesCollection)
          .where('deletedAt', isLessThan: Timestamp.fromDate(cleanupDate))
          .get();

      // Delete old deleted notes
      final batch = firestore.batch();
      for (final doc in oldDeletedNotes.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('--------------------------------');
      debugPrint('Cleaned up ${oldDeletedNotes.docs.length} old deleted notes');
      debugPrint('--------------------------------');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error cleaning up old deleted notes and the expection is $e',
      );
    }
  }

  /// Get deletion statistics for debugging
  static Future<Map<String, dynamic>> getDeletionStats(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Count deleted notes
      final deletedNotesCount = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_deletedNotesCollection)
          .count()
          .get();

      // Count notes marked as deleted
      final deletedNotesInMain = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_notesCollection)
          .where('isDeleted', isEqualTo: true)
          .count()
          .get();

      return {
        'deletedNotesCollection': deletedNotesCount.count,
        'deletedNotesInMain': deletedNotesInMain.count,
        'totalDeleted':
            (deletedNotesCount.count ?? 0) + (deletedNotesInMain.count ?? 0),
        'cleanupThreshold': _cleanupThreshold.inDays,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'cleanupThreshold': _cleanupThreshold.inDays,
      };
    }
  }

  /// Handle sync conflicts between local and remote deletions
  static Future<void> resolveDeletionConflicts(
    List<NoteTakingModel> localNotes,
    String userId,
  ) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();

      for (final note in localNotes) {
        if (note.isDeleted && !note.isDeletionSynced) {
          // Local deletion needs to be synced
          await _addToDeletedNotesCollection(note, userId, deviceId);
          note.isDeletionSynced = true;
        }
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error resolving deletion conflicts and the expection is $e',
      );
    }
  }
}
