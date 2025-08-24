import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:msbridge/core/database/note_taking/note_taking.dart';
import 'package:msbridge/core/services/device_ID/device_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeletionMigrationService {
  static const String _boxName = 'notes';
  static const String _deletedBoxName = 'deleted_notes';
  static const String _migrationFlagKey = 'deletion_migration_done_v1';

  /// Migrate existing data to support the new deletion system
  static Future<void> migrateExistingData() async {
    try {
      // Run once: if already done, skip
      final prefs = await SharedPreferences.getInstance();
      final alreadyDone = prefs.getBool(_migrationFlagKey) ?? false;
      if (alreadyDone) {
        debugPrint('Deletion migration already completed. Skipping.');
        return;
      }
      debugPrint('--------------------------------');
      debugPrint('Starting deletion system migration...');
      debugPrint('--------------------------------');
      // Ensure deleted notes box exists
      await _ensureDeletedNotesBoxExists();

      // Migrate existing deleted notes
      await _migrateExistingDeletedNotes();

      // Update existing notes with new fields
      await _updateExistingNotesWithNewFields();

      // Clean up any orphaned data
      await _cleanupOrphanedData();
      debugPrint('--------------------------------');
      debugPrint('Deletion system migration completed successfully');
      debugPrint('--------------------------------');

      // Mark as done
      await prefs.setBool(_migrationFlagKey, true);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during deletion system migration',
      );
      rethrow;
    }
  }

  /// Ensure the deleted notes box exists
  static Future<void> _ensureDeletedNotesBoxExists() async {
    try {
      if (!Hive.isBoxOpen(_deletedBoxName)) {
        await Hive.openBox<NoteTakingModel>(_deletedBoxName);
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason:
            'Error ensuring deleted notes box exists and the exception is $e',
      );
    }
  }

  static Future<void> migrateExistingData() async {
    // Ensure both boxes exist/open
    await _ensureDeletedNotesBoxExists();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<NoteTakingModel>(_boxName);
    }

    // ... rest of migration logic
  }

  /// Migrate existing deleted notes to the new system
  static Future<void> _migrateExistingDeletedNotes() async {
    try {
      final notesBox = Hive.box<NoteTakingModel>(_boxName);
      final deletedBox = Hive.box<NoteTakingModel>(_deletedBoxName);

      // Find notes that were marked as deleted in the old system
      final oldDeletedNotes =
          notesBox.values.where((note) => note.isDeleted).toList();

      debugPrint(
          'Found ${oldDeletedNotes.length} existing deleted notes to migrate');

      for (final note in oldDeletedNotes) {
        try {
          // Generate device ID for existing notes
          final deviceId = await DeviceIdService.getDeviceId();

          // Update note with new deletion tracking fields
          note.deletedAt = note.updatedAt; // Use updatedAt as deletion time
          note.deletedBy = note.userId; // Use userId as deletedBy
          note.deviceId = deviceId;
          note.isDeletionSynced = false;
          note.lastSyncAt = note.updatedAt;

          // Move to deleted notes box
          await note.delete(); // Remove from main box
          await deletedBox.add(note); // Add to deleted box
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            e,
            StackTrace.current,
            reason:
                'Error migrating note ${note.noteId} and the expection is $e',
          );
        }
      }

      debugPrint(
          'Successfully migrated ${oldDeletedNotes.length} deleted notes');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during deleted notes migration',
      );
    }
  }

  /// Update existing notes with new fields
  static Future<void> _updateExistingNotesWithNewFields() async {
    try {
      final notesBox = Hive.box<NoteTakingModel>(_boxName);
      final deviceId = await DeviceIdService.getDeviceId();

      // Update all existing notes with new fields
      for (final note in notesBox.values) {
        try {
          // Only update if fields are missing
          if (note.deviceId == null) {
            note.deviceId = deviceId;
          }

          if (note.lastSyncAt == null) {
            note.lastSyncAt = note.updatedAt;
          }

          // Save the updated note
          await note.save();
        } catch (e) {
          FirebaseCrashlytics.instance.recordError(
            e,
            StackTrace.current,
            reason:
                'Error updating note ${note.noteId} and the expection is $e',
          );
        }
      }

      debugPrint('Successfully updated existing notes with new fields');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during notes update',
      );
    }
  }

  /// Clean up orphaned data
  static Future<void> _cleanupOrphanedData() async {
    try {
      final notesBox = Hive.box<NoteTakingModel>(_boxName);
      final deletedBox = Hive.box<NoteTakingModel>(_deletedBoxName);

      // Remove any notes that are in both boxes (shouldn't happen)
      final duplicateNotes = <String>[];

      for (final note in notesBox.values) {
        if (note.isDeleted &&
            deletedBox.values.any((d) => d.noteId == note.noteId)) {
          duplicateNotes.add(note.noteId!);
        }
      }

      // Remove duplicates from main box
      for (final noteId in duplicateNotes) {
        final note = notesBox.values.firstWhere((n) => n.noteId == noteId);
        await note.delete();
      }

      if (duplicateNotes.isNotEmpty) {
        debugPrint('--------------------------------');
        debugPrint('Cleaned up ${duplicateNotes.length} duplicate notes');
        debugPrint('--------------------------------');
      }
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during orphaned data cleanup',
      );
    }
  }

  /// Validate migration results
  static Future<Map<String, dynamic>> validateMigration() async {
    try {
      final notesBox = Hive.box<NoteTakingModel>(_boxName);
      final deletedBox = Hive.box<NoteTakingModel>(_deletedBoxName);

      final activeNotes =
          notesBox.values.where((note) => !note.isDeleted).length;
      final deletedNotes = deletedBox.values.length;
      final totalNotes = activeNotes + deletedNotes;

      // Check for notes with missing required fields
      final notesWithMissingFields = notesBox.values
          .where((note) => note.deviceId == null || note.lastSyncAt == null)
          .length;

      final deletedNotesWithMissingFields = deletedBox.values
          .where((note) => note.deviceId == null || note.deletedAt == null)
          .length;

      return {
        'totalNotes': totalNotes,
        'activeNotes': activeNotes,
        'deletedNotes': deletedNotes,
        'notesWithMissingFields': notesWithMissingFields,
        'deletedNotesWithMissingFields': deletedNotesWithMissingFields,
        'migrationSuccessful':
            notesWithMissingFields == 0 && deletedNotesWithMissingFields == 0,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'migrationSuccessful': false,
      };
    }
  }

  /// Rollback migration if needed
  static Future<void> rollbackMigration() async {
    try {
      debugPrint('--------------------------------');
      debugPrint('Rolling back deletion system migration...');
      debugPrint('--------------------------------');
      final notesBox = Hive.box<NoteTakingModel>(_boxName);
      final deletedBox = Hive.box<NoteTakingModel>(_deletedBoxName);

      // Move all deleted notes back to main box
      final deletedNotes = deletedBox.values.toList();
      for (final note in deletedNotes) {
        // Reset deletion fields
        note.isDeleted = false;
        note.deletedAt = null;
        note.deletedBy = null;
        note.deviceId = null;
        note.isDeletionSynced = false;
        note.lastSyncAt = null;

        // Move back to main box
        await note.delete(); // Remove from deleted box
        await notesBox.add(note); // Add to main box
      }

      // Close deleted notes box
      await deletedBox.close();

      debugPrint('--------------------------------');
      debugPrint('Migration rollback completed successfully');
      debugPrint('--------------------------------');
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error during migration rollback',
      );
      rethrow;
    }
  }

  /// Get migration status
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final notesBox = Hive.box<NoteTakingModel>(_boxName);
      final deletedBox = Hive.box<NoteTakingModel>(_deletedBoxName);

      final hasDeletedBox = Hive.isBoxOpen(_deletedBoxName);
      final totalNotes = notesBox.values.length;
      final deletedNotes = hasDeletedBox ? deletedBox.values.length : 0;

      return {
        'hasDeletedBox': hasDeletedBox,
        'totalNotes': totalNotes,
        'deletedNotes': deletedNotes,
        'migrationRequired':
            !hasDeletedBox || totalNotes > 0 && deletedNotes == 0,
      };
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(
        e,
        StackTrace.current,
        reason: 'Error getting migration status and the expection is $e',
      );
      return {
        'error': e.toString(),
        'migrationRequired': true,
      };
    }
  }
}
