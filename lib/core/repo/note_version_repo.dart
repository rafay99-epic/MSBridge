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
}
