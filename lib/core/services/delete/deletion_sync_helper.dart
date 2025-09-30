// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Project imports:
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/services/delete/deletion_migration_service.dart';
import 'package:msbridge/core/services/delete/deletion_sync_integration_service.dart';
import 'package:msbridge/core/services/device_ID/device_id_service.dart';

/// Simple helper service for integrating deletion sync with existing operations
class DeletionSyncHelper {
  /// Initialize deletion sync system for a user (call this on login)
  static Future<void> initializeForUser(String userId) async {
    try {
      debugPrint('🚀 Initializing deletion sync system for user: $userId');

      // Ensure device ID is generated
      await DeviceIdService.getDeviceId();

      // Check if migration is needed
      final migrationStatus =
          await DeletionMigrationService.getMigrationStatus();
      if (migrationStatus['migrationRequired'] == true) {
        debugPrint('📋 Migration required, starting...');
        await DeletionMigrationService.migrateExistingData();

        // Validate migration
        final validation = await DeletionMigrationService.validateMigration();
        debugPrint(
            'Migration validation: ${validation['migrationSuccessful']}');
      }

      // Initialize the deletion sync system
      await DeletionSyncIntegrationService.initializeForUser(userId);

      debugPrint('✅ Deletion sync system ready for user: $userId');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error initializing deletion sync system',
      );
      debugPrint('❌ Error initializing deletion sync system: $e');
    }
  }

  /// Handle note deletion with proper sync
  static Future<void> deleteNote(NoteTakingModel note, String userId) async {
    try {
      await DeletionSyncIntegrationService.handleNoteDeletion(note, userId);
      debugPrint('✅ Note deleted and synced: ${note.noteTitle}');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error handling note deletion',
      );
      debugPrint('❌ Error deleting note: $e');
      rethrow;
    }
  }

  /// Handle note restoration with proper sync
  static Future<void> restoreNote(NoteTakingModel note, String userId) async {
    try {
      await DeletionSyncIntegrationService.handleNoteRestoration(note, userId);
      debugPrint('✅ Note restored and synced: ${note.noteTitle}');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error handling note restoration',
      );
      debugPrint('❌ Error restoring note: $e');
      rethrow;
    }
  }

  /// Trigger immediate deletion sync (useful for manual sync operations)
  static Future<void> triggerImmediateSync(String userId) async {
    try {
      debugPrint('🔄 Triggering immediate deletion sync for user: $userId');

      // Process deletions during sync
      await DeletionSyncIntegrationService.processDeletionsDuringSync(userId);

      // Resolve conflicts
      await DeletionSyncIntegrationService.resolveDeletionConflicts(userId);

      debugPrint('✅ Immediate deletion sync completed');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error in immediate deletion sync',
      );
      debugPrint('❌ Error in immediate deletion sync: $e');
      rethrow;
    }
  }

  /// Get deletion sync status for monitoring
  static Future<Map<String, dynamic>> getSyncStatus(String userId) async {
    try {
      return await DeletionSyncIntegrationService.getDeletionSyncStatus(userId);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error getting deletion sync status',
      );
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Validate deletion sync system health
  static Future<bool> validateSystemHealth(String userId) async {
    try {
      final validation =
          await DeletionSyncIntegrationService.validateDeletionSyncSystem(
              userId);
      return validation['isConfigured'] == true;
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error validating deletion sync system health',
      );
      return false;
    }
  }

  /// Emergency rollback if needed
  static Future<void> emergencyRollback(String userId) async {
    try {
      debugPrint('⚠️ Starting emergency rollback...');
      await DeletionMigrationService.rollbackMigration();
      debugPrint('✅ Emergency rollback completed');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during emergency rollback',
      );
      debugPrint('❌ Error during emergency rollback: $e');
      rethrow;
    }
  }
}
