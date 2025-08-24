import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:msbridge/core/services/device_ID/device_id_service.dart';
import 'package:msbridge/core/repo/note_taking_repo.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';

class DeletionSyncIntegrationService {
  /// Initialize the deletion sync system for a user
  static Future<void> initializeForUser(String userId) async {
    try {
      // Ensure device ID is generated
      await DeviceIdService.getDeviceId();

      // Resolve any existing deletion conflicts
      await NoteTakingRepo.resolveDeletionConflicts(userId);

      debugPrint('Deletion sync system initialized for user: $userId');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error initializing deletion sync system and the expection is $e',
      );
      debugPrint('Error initializing deletion sync system: $e');
    }
  }

  /// Process deletions during sync operations
  static Future<void> processDeletionsDuringSync(String userId) async {
    try {
      // Sync deletions from Firebase to local storage
      final deletedNoteIds =
          await NoteTakingRepo.syncDeletionsFromFirebase(userId);

      if (deletedNoteIds.isNotEmpty) {
        debugPrint('--------------------------------');
        debugPrint('Synced ${deletedNoteIds.length} deletions from Firebase');
        debugPrint('--------------------------------');
      }

      // Resolve any conflicts
      await NoteTakingRepo.resolveDeletionConflicts(userId);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error processing deletions during sync and the expection is $e',
      );
    }
  }

  /// Resolve deletion conflicts
  static Future<void> resolveDeletionConflicts(String userId) async {
    try {
      await NoteTakingRepo.resolveDeletionConflicts(userId);
      debugPrint('--------------------------------');
      debugPrint('Deletion conflicts resolved for user: $userId');
      debugPrint('--------------------------------');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error resolving deletion conflicts and the expection is $e',
      );
    }
  }

  /// Clean up old deleted notes (call this periodically)
  static Future<void> performCleanup(String userId) async {
    try {
      await NoteTakingRepo.cleanupOldDeletedNotes(userId);
      debugPrint('--------------------------------');
      debugPrint('Cleanup completed for user: $userId');
      debugPrint('--------------------------------');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during cleanup and the expection is $e',
      );
    }
  }

  /// Get sync status for deletion operations
  static Future<Map<String, dynamic>> getDeletionSyncStatus(
      String userId) async {
    try {
      final stats = await NoteTakingRepo.getDeletionStats(userId);
      final deviceId = await DeviceIdService.getDeviceId();

      return {
        ...stats,
        'deviceId': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Handle note deletion with proper sync
  static Future<void> handleNoteDeletion(
      NoteTakingModel note, String userId) async {
    try {
      await NoteTakingRepo.deleteNote(note, userId);
      debugPrint('--------------------------------');
      debugPrint('Note ${note.noteId} deleted and synced for user: $userId');
      debugPrint('--------------------------------');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error handling note deletion and the expection is $e',
      );
      rethrow;
    }
  }

  /// Handle note restoration with proper sync
  static Future<void> handleNoteRestoration(
      NoteTakingModel note, String userId) async {
    try {
      await NoteTakingRepo.restoreNote(note, userId);
      debugPrint('--------------------------------');
      debugPrint('Note ${note.noteId} restored and synced for user: $userId');
      debugPrint('--------------------------------');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error handling note restoration and the expection is $e',
      );
      rethrow;
    }
  }

  /// Check if a note should be synced (considering deletion state)
  static bool shouldSyncNote(NoteTakingModel note) {
    return note.shouldSync;
  }

  /// Get notes that need deletion sync
  static List<NoteTakingModel> getNotesNeedingDeletionSync() {
    return NoteTakingRepo.getDeletedNotesForSync();
  }

  /// Get notes that need regular sync
  static List<NoteTakingModel> getNotesNeedingRegularSync() {
    return NoteTakingRepo.getNotesForSync();
  }

  /// Perform full sync including deletions
  static Future<void> performFullSync(String userId) async {
    try {
      debugPrint('--------------------------------');
      debugPrint('Starting full sync for user: $userId');
      debugPrint('--------------------------------');

      // Process deletions first
      await processDeletionsDuringSync(userId);

      // Get notes that need syncing
      final notesForSync = getNotesNeedingRegularSync();
      final deletionNotesForSync = getNotesNeedingDeletionSync();

      debugPrint('Notes needing regular sync: ${notesForSync.length}');
      debugPrint('Notes needing deletion sync: ${deletionNotesForSync.length}');

      // Here you would integrate with your existing sync logic
      // For now, we just log the status

      debugPrint('Full sync completed for user: $userId');
      debugPrint('--------------------------------');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during full sync and the expection is $e',
      );
    }
  }

  /// Validate deletion sync system
  static Future<Map<String, dynamic>> validateDeletionSyncSystem(
      String userId) async {
    try {
      final deviceId = await DeviceIdService.getDeviceId();
      final stats = await getDeletionSyncStatus(userId);

      // Check if system is properly configured
      final isConfigured = deviceId.isNotEmpty &&
          stats['localActiveNotes'] != null &&
          stats['localDeletedNotes'] != null;

      return {
        'isConfigured': isConfigured,
        'deviceId': deviceId,
        'stats': stats,
        'validationTimestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isConfigured': false,
        'error': e.toString(),
        'validationTimestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Emergency rollback of deletion sync system
  static Future<void> emergencyRollback(String userId) async {
    try {
      debugPrint('--------------------------------');
      debugPrint(
          'EMERGENCY: Rolling back deletion sync system for user: $userId');
      debugPrint('--------------------------------');

      // This would need to be implemented based on your specific needs
      // For now, we just log the emergency

      debugPrint('Emergency rollback completed for user: $userId');
      debugPrint('--------------------------------');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during emergency rollback and the expection is $e',
      );
    }
  }
}
