import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:msbridge/core/database/note_taking/note_version.dart';
import 'package:msbridge/core/utils/version_diff_utils.dart';
import 'package:msbridge/utils/uuid.dart';

class NoteVersionRepo {
  static const String _boxName = 'note_versions';
  static Box<NoteVersion>? _box;

  NoteVersionRepo._();

  static final NoteVersionRepo _instance = NoteVersionRepo._();

  factory NoteVersionRepo() => _instance;

  static Future<Box<NoteVersion>> getBox() async {
    if (_box == null || !_box!.isOpen) {
      try {
        _box = await Hive.openBox<NoteVersion>(_boxName);
      } catch (e) {
        throw Exception('Error opening Hive box "$_boxName": $e');
      }
    }
    return _box!;
  }

  static Future<void> createVersion({
    required String noteId,
    required String noteTitle,
    required String noteContent,
    required List<String> tags,
    required String userId,
    required int versionNumber,
    String changeDescription = '',
    String? previousVersionId,
  }) async {
    try {
      final box = await getBox();

      // Get the previous version to detect changes
      NoteVersion? previousVersion;
      if (previousVersionId != null && previousVersionId.isNotEmpty) {
        previousVersion = await getVersion(previousVersionId);
      }

      // Detect what changed in this version
      final changes = previousVersion != null
          ? VersionDiffUtils.detectChanges(
              oldTitle: previousVersion.noteTitle,
              newTitle: noteTitle,
              oldContent: previousVersion.noteContent,
              newContent: noteContent,
              oldTags: previousVersion.tags,
              newTags: tags,
            )
          : ['Initial version'];

      final version = NoteVersion(
        versionId: generateUuid(),
        noteId: noteId,
        noteTitle: noteTitle,
        noteContent: noteContent,
        tags: tags,
        createdAt: DateTime.now(),
        userId: userId,
        changeDescription: changeDescription.isNotEmpty
            ? changeDescription
            : VersionDiffUtils.generateChangeDescription(changes),
        versionNumber: versionNumber,
        changes: changes,
        previousVersionId: previousVersionId ?? '',
      );

      await box.add(version);
    } catch (e) {
      throw Exception('Error creating note version: $e');
    }
  }

  static Future<List<NoteVersion>> getNoteVersions(String noteId) async {
    try {
      final box = await getBox();
      final versions =
          box.values.where((version) => version.noteId == noteId).toList();

      // Sort by version number descending (newest first)
      versions.sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
      return versions;
    } catch (e) {
      throw Exception('Error getting note versions: $e');
    }
  }

  static Future<NoteVersion?> getVersion(String versionId) async {
    try {
      final box = await getBox();
      return box.values.firstWhere(
        (version) => version.versionId == versionId,
        orElse: () => NoteVersion(
          noteId: '',
          noteTitle: '',
          noteContent: '',
          tags: [],
          createdAt: DateTime.now(),
          userId: '',
          versionNumber: 1,
        ),
      );
    } catch (e) {
      throw Exception('Error getting version: $e');
    }
  }

  static Future<NoteVersion?> getPreviousVersion(
      String noteId, int currentVersionNumber) async {
    try {
      final box = await getBox();
      final versions = box.values
          .where((version) =>
              version.noteId == noteId &&
              version.versionNumber < currentVersionNumber)
          .toList();

      if (versions.isEmpty) return null;

      // Get the version with the highest number that's still less than current
      versions.sort((a, b) => b.versionNumber.compareTo(a.versionNumber));
      return versions.first;
    } catch (e) {
      throw Exception('Error getting previous version: $e');
    }
  }

  static Future<void> deleteOldVersions(String noteId, int keepCount) async {
    try {
      final versions = await getNoteVersions(noteId);

      if (versions.length > keepCount) {
        final toDelete = versions.sublist(keepCount);
        for (final version in toDelete) {
          await version.delete();
        }
      }
    } catch (e) {
      throw Exception('Error deleting old versions: $e');
    }
  }

  static Future<void> deleteAllVersionsForNote(String noteId) async {
    try {
      final box = await getBox();
      final versions =
          box.values.where((version) => version.noteId == noteId).toList();

      for (final version in versions) {
        await version.delete();
      }
    } catch (e) {
      throw Exception('Error deleting all versions for note: $e');
    }
  }

  static Future<int> getVersionCount(String noteId) async {
    try {
      final box = await getBox();
      return box.values.where((version) => version.noteId == noteId).length;
    } catch (e) {
      throw Exception('Error getting version count: $e');
    }
  }

  static Future<void> clearAllVersions() async {
    try {
      final box = await getBox();
      await box.clear();
    } catch (e) {
      throw Exception('Error clearing all versions: $e');
    }
  }

  /// Get a summary of changes for a specific version
  static String getVersionChangeSummary(NoteVersion version) {
    return VersionDiffUtils.getVersionSummary(version);
  }

  /// Compare two versions and get detailed differences
  static Map<String, dynamic> compareVersions(
      NoteVersion? oldVersion, NoteVersion newVersion) {
    return VersionDiffUtils.compareVersions(oldVersion, newVersion);
  }

  /// Restore a specific version to create a new note
  static Future<NoteVersion> restoreVersion({
    required NoteVersion versionToRestore,
    required String newNoteId,
    required String userId,
  }) async {
    try {
      final box = await getBox();

      // Create a new version from the restored content
      final restoredVersion = versionToRestore.createRestoredVersion(
        newNoteId: newNoteId,
        userId: userId,
        newVersionNumber: 1, // Start fresh with version 1
      );

      // Add to the versions box
      await box.add(restoredVersion);

      return restoredVersion;
    } catch (e) {
      throw Exception('Error restoring version: $e');
    }
  }

  /// Get all versions for a specific note, sorted by version number
  static Future<List<NoteVersion>> getVersionsForNote(String noteId) async {
    try {
      final box = await getBox();
      final versions =
          box.values.where((version) => version.noteId == noteId).toList();

      // Sort by version number ascending (oldest first)
      versions.sort((a, b) => a.versionNumber.compareTo(b.versionNumber));
      return versions;
    } catch (e) {
      throw Exception('Error getting versions for note: $e');
    }
  }

  /// Export version data for download
  static Map<String, dynamic> exportVersionData(NoteVersion version) {
    return {
      'versionId': version.versionId,
      'noteId': version.noteId,
      'noteTitle': version.noteTitle,
      'noteContent': version.noteContent,
      'tags': version.tags,
      'createdAt': version.createdAt.toIso8601String(),
      'userId': version.userId,
      'changeDescription': version.changeDescription,
      'versionNumber': version.versionNumber,
      'changes': version.changes,
      'exportedAt': DateTime.now().toIso8601String(),
      'exportFormat': 'MSBridge_Note_Version',
    };
  }

  /// Get all versions from the database
  static Future<List<NoteVersion>> getAllVersions() async {
    try {
      final box = await getBox();
      return box.values.toList();
    } catch (e) {
      throw Exception('Error getting all versions: $e');
    }
  }

  /// Clear all versions for a specific user
  static Future<void> clearVersionsForUser(String userId) async {
    try {
      final box = await getBox();
      final versionsToDelete =
          box.values.where((version) => version.userId == userId).toList();

      for (final version in versionsToDelete) {
        await box.delete(version.key);
      }
    } catch (e) {
      throw Exception('Error clearing versions for user: $e');
    }
  }

  /// Update an existing version
  static Future<void> updateVersion(NoteVersion version) async {
    try {
      final box = await getBox();
      final existingVersion =
          box.values.firstWhere((v) => v.versionId == version.versionId);

      await box.put(existingVersion.key, version);
    } catch (e) {
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      throw Exception('Error updating version: $e');
    }
  }

  /// Clear all versions for a specific note
  static Future<void> clearVersionsForNote(String noteId) async {
    try {
      final box = await getBox();
      final versionsToDelete =
          box.values.where((version) => version.noteId == noteId).toList();

      for (final version in versionsToDelete) {
        await box.delete(version.key);
      }
    } catch (e) {
      throw Exception('Error clearing versions for note: $e');
    }
  }

  /// Clean up old versions based on max versions setting
  static Future<Map<String, dynamic>> cleanupOldVersions(
      int maxVersionsToKeep) async {
    try {
      final box = await getBox();
      final allVersions = box.values.toList();

      // Group versions by noteId
      final Map<String, List<NoteVersion>> noteVersions = {};
      for (final version in allVersions) {
        noteVersions.putIfAbsent(version.noteId, () => []).add(version);
      }

      int totalDeleted = 0;
      int totalNotesAffected = 0;

      // Process each note's versions
      for (final noteId in noteVersions.keys) {
        final versions = noteVersions[noteId]!;
        if (versions.length > maxVersionsToKeep) {
          // Sort by version number (oldest first)
          versions.sort((a, b) => a.versionNumber.compareTo(b.versionNumber));

          // Keep only the latest maxVersionsToKeep versions
          final versionsToDelete =
              versions.take(versions.length - maxVersionsToKeep).toList();

          // Delete old versions
          for (final version in versionsToDelete) {
            await box.delete(version.key);
            totalDeleted++;
          }

          totalNotesAffected++;
        }
      }

      return {
        'success': true,
        'message':
            'Cleanup completed: $totalDeleted versions deleted from $totalNotesAffected notes',
        'deletedCount': totalDeleted,
        'notesAffected': totalNotesAffected,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error during cleanup: $e',
        'deletedCount': 0,
        'notesAffected': 0,
      };
    }
  }

  /// Get total version count across all notes
  static Future<int> getTotalVersionCount() async {
    try {
      final box = await getBox();
      return box.length;
    } catch (e) {
      throw Exception('Error getting total version count: $e');
    }
  }

  /// Get storage usage information
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final box = await getBox();
      final allVersions = box.values.toList();

      // Group by noteId to count unique notes
      final uniqueNotes = allVersions.map((v) => v.noteId).toSet().length;

      // Calculate total content size (rough estimate)
      int totalContentSize = 0;
      for (final version in allVersions) {
        totalContentSize += version.noteContent.length;
        totalContentSize += version.noteTitle.length;
        totalContentSize += version.tags.join('').length;
      }

      return {
        'totalVersions': allVersions.length,
        'uniqueNotes': uniqueNotes,
        'totalContentSize': totalContentSize,
        'averageVersionsPerNote':
            uniqueNotes == 0 ? 0.0 : allVersions.length / uniqueNotes,
        'oldestVersion': allVersions.isNotEmpty
            ? allVersions
                .map((v) => v.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b)
                .toIso8601String()
            : null,
        'newestVersion': allVersions.isNotEmpty
            ? allVersions
                .map((v) => v.createdAt)
                .reduce((a, b) => a.isAfter(b) ? a : b)
                .toIso8601String()
            : null,
      };
    } catch (e) {
      throw Exception('Error getting storage info: $e');
    }
  }
}
